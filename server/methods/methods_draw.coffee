Meteor.methods
  "addTaskBefore": (task) ->
    console.log "starting addTaskBefore:", task
    accountId = Meteor.user().profile.accountId
    tasks = Tasks.find({flowId: task.flowId}).fetch()
    #console.log "tasks:", tasks
    # найти максимальную позицию
    maxPos = parseInt(_.max(tasks, (task) -> task.pos).pos)
    # добавить новую со ссылкой на следующую
    newTask = {}
    newTask.accountId = accountId
    newTask.nextPos = []
    newTask.nextPos.push task.pos
    newTask.flowId = task.flowId
    newTask.pos = maxPos + 1
    newTask.type = "task"
    if not task.roleId?
      taskFound = Tasks.findOne({flowId:task.flowId, roleId: {$exists: true}})
      if taskFound?
        newTask.roleId = taskFound.roleId
      else
        newTask.roleId = "unassigned"
    else
      newTask.roleId = task.roleId
    console.log "newTask.roleId:#{newTask.roleId}"
    newTask.editMode = true
    newTaskId = Tasks.insert newTask
    #console.log "newTaskId:",newTaskId
    for eachTask in tasks
      #console.log "iterating thru:", eachTask
      # найти каждую ссылающуюся задачу
      if eachTask.nextPos?
        if _.contains(eachTask.nextPos, task.pos)
          newPos = _.without(eachTask.nextPos, task.pos)
          newPos.push newTask.pos
          Tasks.update({_id: eachTask._id}, {$set: {nextPos: _.uniq(newPos)}})
      # найти каждое ссылающееся решение
      if eachTask.decisions?
        for decision in eachTask.decisions
          if _.contains(decision.nextPos, task.pos)
            newPos = _.without(decision.nextPos, task.pos)
            newPos.push newTask.pos
            Tasks.update({_id: eachTask._id, "decisions.id": decision.id}, {$set: {"decisions.$.nextPos": _.uniq(newPos)}})

  "saveEditedTask": (task, editMode) ->
    Tasks.update({_id: task._id}, {$set: {
      name: task.name
      instructions: task.instructions
      editMode: editMode
      roleId: task.roleId
      }})

  "startEditingTask": (task) ->
    Tasks.update({_id: task._id}, {$set: {editMode: true}})

  "deleteTask": (task) ->
    tasks = Tasks.find({flowId: task.flowId}).fetch()
    nextPosisions = []
    if task.decisions?
      for decision in task.decisions
        for pos in decision.nextPos
          nextPosisions.push pos
    else
      nextPosisions = task.nextPos
    console.log "nextPosisions:",nextPosisions
    for eachTask in tasks
      # найти каждую ссылающуюся задачу
      if _.contains(eachTask.nextPos, task.pos)
        # найти все задачи, ссылающиеся на нее, и перевести на нее
        newPos = _.without(eachTask.nextPos, task.pos)
        for pos in nextPosisions
          newPos.push pos
        console.log "newPos in simple:", newPos
        Tasks.update({_id: eachTask._id}, {$set: {"nextPos": _.uniq(newPos)}})
      # найти каждое ссылающееся решение
      if eachTask.decisions?
        for decision in eachTask.decisions
          if decision.nextPos?
            console.log "decision.nextPos:", decision.nextPos, ",  task.pos:", task.pos
            if _.contains(decision.nextPos, task.pos)
              # первести его на новое
              newPos = _.without(decision.nextPos, task.pos)
              for pos in nextPosisions
                newPos.push pos
              console.log "newPos in decisions:", newPos
              Tasks.update({_id: eachTask._id, "decisions.id": decision.id}, {$set: {"decisions.$.nextPos": newPos}})
    Tasks.remove _id: task._id

  "makeTaskConnection": (sourceId, targetId) ->
    sourceId = sourceId.replace("new-connection-from-", "")
    console.log "makeTaskConnection started, sId:#{sourceId}, tId:#{targetId}"
    sourceTask = Tasks.findOne({_id: sourceId})
    targetTask = Tasks.findOne({_id: targetId})
    hasLoops = willHaveLoops(Tasks.find({flowId: sourceTask.flowId}).fetch(), {sourcePos: sourceTask.pos, targetPos: targetTask.pos})
    console.log "hasLoops:", hasLoops
    if hasLoops
      throw new Meteor.Error 500, "Loops will be made, aboring"
    newPos = _.without(sourceTask.nextPos, targetTask.pos)
    newPos.push targetTask.pos
    console.log "new nextPos:", newPos
    Tasks.update({_id: sourceTask._id}, {$set: {"nextPos": _.uniq(newPos)}})

  "removeTaskConnection": (sourceId, destinationId) ->
    sourceTask = Tasks.findOne({_id: sourceId})
    destTask = Tasks.findOne({_id: destinationId})
    Tasks.update({_id: sourceId}, {$set: {nextPos: _.uniq(_.without(sourceTask.nextPos, destTask.pos))}})

  "addDecision": (task, newDecisionName) ->
    newDecision = {}
    newDecision.name = newDecisionName
    newDecision.id = uuid.v4()
    endTask = Tasks.findOne({flowId: task.flowId, type: "end"})
    newDecision.nextPos = [endTask.pos]
    console.log "newDecision:", newDecision
    Tasks.update({_id: task._id}, {$push: {decisions: newDecision}})

  "removeTaskDecision": (taskId, decisionIdToRemove) ->
    console.log "removeTaskDecision started, taskId:#{taskId}, decisionIdToRemove:#{decisionIdToRemove}"
    Tasks.update({_id: taskId}, {$pull: {decisions: {id: decisionIdToRemove}}})

  "makeDecisionConnection": (dataObject) ->
    console.log "makeDecisionConnection started, dataObject:#{dataObject}"
    newPos = Tasks.findOne({_id: dataObject.targetId}).pos
    console.log "newPos:", newPos
    newPosArray = []
    newPosArray.push newPos
    Tasks.update({_id: dataObject.taskId, "decisions.id": dataObject.decisionId}, {$set: {"decisions.$.nextPos": _.uniq(newPosArray)}})

@willHaveLoops = (tasks, proposedConnection) ->
  # proposedConnection = {sourcePos: pos1, targetPos: pos2, sourceDecisionId: id1, targetDecisionPos: pos}
  #console.log "tasks:", tasks
  startTask = _.findWhere(tasks, {type: "start"})
  for task in tasks
    task.passed = false
  hasLoop = checkForLoopsInternal(startTask, tasks, proposedConnection)
  for task in tasks
    task.passed = false
  return hasLoop


@checkForLoopsInternal = (task, tasks, proposedConnection) ->
  if not task?
    return false
  if task.passed
    return true
  else
    task.passed = true
  if task.nextPos?
    for nextPos in task.nextPos
      nextTask = _.findWhere(tasks, {pos: nextPos})
      checkForLoopsInternal(nextTask, tasks, proposedConnection)
    if proposedConnection.sourcePos?
      if proposedConnection.sourcePos == task.pos
        nextTask = _.findWhere(tasks, {pos: proposedConnection.targetPos})
        checkForLoopsInternal(nextTask, tasks, proposedConnection)
  else if task.decisions?
    for decision in task.decisions
      for nextPos in decision.nextPos
        nextTask = _.findWhere(tasks, {pos: nextPos})
        checkForLoopsInternal(nextTask, tasks, proposedConnection)
      if proposedConnection.sourceDecisionId?
        if proposedConnection.sourceDecisionId == decision.id
          nextTask = _.findWhere(tasks, {pos: proposedConnection.targetDecisionPos})
          checkForLoopsInternal(nextTask, tasks, proposedConnection)
  return false
