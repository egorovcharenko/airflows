@createEmptyTask = (task, accountId, tasks) ->
  # добавить новую со ссылкой на следующую
  newTask = {}
  newTask.accountId = accountId
  newTask.nextPos = []
  newTask.flowId = task.flowId
  newTask.pos = uuid.v4()
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
  return newTask

Meteor.methods
  "addTaskBefore": (task) ->
    console.log "starting addTaskBefore:", task
    accountId = Meteor.user().profile.accountId
    tasks = Tasks.find({flowId: task.flowId}).fetch()
    newTask = createEmptyTask task, accountId, tasks
    newTask.nextPos.push task.pos
    newTaskId = Tasks.insert newTask
    #console.log "newTaskId:",newTaskId
    for eachTask in tasks
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

  "addTaskToTheSide": (task) ->
    console.log "addTaskToTheSide started, task:#{task}"
    # создаем новую задачу
    accountId = Meteor.user().profile.accountId
    tasks = Tasks.find({flowId: task.flowId}).fetch()
    newTask = createEmptyTask task, accountId, tasks
    # проставляем исходящую ссылку
    if task.decisions?
      newTask.nextPos = task.decisions[0].nextPos
    else
      newTask.nextPos = task.nextPos
    newTaskId = Tasks.insert newTask
    #console.log "newTaskId:",newTaskId

    # добавляем ссылки на нее у всех ссылающихся
    for eachTask in tasks
      # найти каждую ссылающуюся задачу
      if eachTask.nextPos?
        if _.contains(eachTask.nextPos, task.pos)
          newPos = eachTask.nextPos
          newPos.push newTask.pos
          Tasks.update({_id: eachTask._id}, {$set: {nextPos: _.uniq(newPos)}})
      # найти каждое ссылающееся решение
      if eachTask.decisions?
        for decision in eachTask.decisions
          if _.contains(decision.nextPos, task.pos)
            newPos = decision.nextPos
            newPos.push newTask.pos
            Tasks.update({_id: eachTask._id, "decisions.id": decision.id}, {$set: {"decisions.$.nextPos": _.uniq(newPos)}})

  "addTaskAfter": (dataObject) ->
    console.log "addTaskAfter started, dataObject:", dataObject
    accountId = Meteor.user().profile.accountId
    sourceTask = Tasks.findOne({_id: dataObject.sourceId})
    destTask = Tasks.findOne({_id: dataObject.destinationId})
    console.log "sourceTask:", sourceTask, ", destTask:", destTask

    tasks = Tasks.find({flowId: sourceTask.flowId}).fetch()
    # создаем новую задачу
    newTask = createEmptyTask sourceTask, accountId, tasks
    # проставляем ссылку у новой задачи на следующую задачу
    newTask.nextPos = sourceTask.nextPos
    # записываем задачу
    newTaskId = Tasks.insert newTask
    console.log "newTask:", newTask
    # проставляем ссылку у старой задачи - на новую задачу
    sourceNextPos = sourceTask.nextPos
    newPos = _.without(sourceNextPos, destTask.pos)
    newPos.push newTask.pos
    Tasks.update({_id: sourceTask._id}, {$set: {nextPos: _.uniq(newPos)}})
    console.log "new source task:", Tasks.findOne({_id: dataObject.sourceId})

  "saveEditedTask": (task, editMode) ->
    Tasks.update({_id: task._id}, {$set: {
      name: task.name
      instructions: task.instructions
      editMode: editMode
      roleId: task.roleId
      timing: task.timing
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
      # если ссылок больше одной, то просто удалить ссылку
      if eachTask.nextPos?
        if eachTask.nextPos.length > 1
          Tasks.update({_id: eachTask._id}, {$set: {"nextPos": _.without(eachTask.nextPos, task.pos)}})
          continue
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
    if sourceId == targetId
      throw new Meteor.Error 500, "Невозможно связать задачу саму с собой"
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
    console.log "removeTaskConnection, sourceId:#{sourceId}, destinationId:#{destinationId}"
    sourceTask = Tasks.findOne({_id: sourceId})
    destTask = Tasks.findOne({_id: destinationId})
    Tasks.update({_id: sourceId}, {$set: {nextPos: _.uniq(_.without(sourceTask.nextPos, destTask.pos))}})

  "addDecision": (task, newDecisionName) ->
    #console.log "task:", task
    currentDecisions = task.decisions
    newDecision = {}
    newDecision.name = newDecisionName
    newDecision.id = uuid.v4()
    if currentDecisions?
      endTask = Tasks.findOne({flowId: task.flowId, type: "end"})
      newDecision.nextPos = [endTask.pos]
    else
      newDecision.nextPos = task.nextPos
      Tasks.update({_id: task._id}, {$set: {nextPos: null, decisions: []}})
    console.log "newDecision:", newDecision
    Tasks.update({_id: task._id}, {$push: {decisions: newDecision}})

  "removeTaskDecision": (taskId, decisionIdToRemove) ->
    console.log "removeTaskDecision started, taskId:#{taskId}, decisionIdToRemove:#{decisionIdToRemove}"
    decisions = Tasks.findOne({_id: taskId}).decisions
    decisionsCount = decisions.length
    console.log "decisionsCount:", decisionsCount
    if decisionsCount > 1
      Tasks.update({_id: taskId}, {$pull: {decisions: {id: decisionIdToRemove}}})
    else
      nextPos = _.findWhere(decisions, {id: decisionIdToRemove}).nextPos
      # поставить следующую задачу
      Tasks.update({_id: taskId}, {$set: {"nextPos": _.uniq(nextPos)}})

      # удалить последнее решение
      Tasks.update({_id: taskId}, {$pull: {decisions: {id: decisionIdToRemove}}})

      # обнулить решения
      Tasks.update({_id: taskId}, {$set: {decisions: null}})


  "makeDecisionConnection": (dataObject) ->
    console.log "makeDecisionConnection started, dataObject:#{dataObject}"
    newPos = Tasks.findOne({_id: dataObject.targetId}).pos
    console.log "newPos:", newPos
    newPosArray = []
    newPosArray.push newPos
    Tasks.update({_id: dataObject.taskId, "decisions.id": dataObject.decisionId}, {$set: {"decisions.$.nextPos": _.uniq(newPosArray)}})

  "addDataField": (dataObject) ->
    console.log "addDataField started, dataObject:", dataObject
    # найти объект
    entity = Entities.findOne({name: dataObject.entityName})
    if not entity?
      throw new Meteor.Error 500, "Не найден объект, к которому надо добавить поле"
    # проверить что такое поле не существует
    if _.findWhere(entity.fields, {name: dataObject.fieldName})?
      throw new Meteor.Error 500, "Поле с таким названием уже найдено"
    # добавить поле
    newField = {
      name: dataObject.fieldName
    }
    Entities.update({name: dataObject.entityName}, {$push: {fields: newField}})

  "removeDataField": (dataObject) ->
    console.log "removeDataField started, dataObject:", dataObject
    # найти объект
    entity = Entities.findOne({name: dataObject.entityName})
    if not entity?
      throw new Meteor.Error 500, "Не найден объект, у которого надо удалить поле"
    # удалить поле
    Entities.update({name: dataObject.entityName}, {$pull: {fields: {name: dataObject.fieldName}}})

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
