Meteor.methods
  "runFlow": (dataObject) ->
    # создать экземпляр
    flowInstance = {}
    flowInstance.flowId = dataObject._id
    flowInstance.name = if dataObject.insName then dataObject.insName else dataObject.prettyName
    flowInstance.state = "running"
    if dataObject.parentTaskInsId?
      flowInstance.parentTaskInsId = dataObject.parentTaskInsId
    # сохранить
    flowInsId = FlowsIns.insert flowInstance
    # скопировать задания в экземпляры
    tasks = (Tasks.find({flowName: dataObject.name})).fetch()
    for task in tasks
      taskIns = task
      delete taskIns._id
      taskIns.flowInsId = flowInsId
      taskIns.state = "new"
      taskInsId = TasksIns.insert taskIns
      if task.type == "start"
        startTask = task
    # установить первую задачу для выполнения
    TasksIns.update({flowInsId: flowInsId, pos: startTask.nextPos[0]}, {$set: {state: "current"}})
    # если привязана сущность - создать ее
    if dataObject.entityName?
      ent = Entities.findOne({name: dataObject.entityName})
      if not ent?
        throw new Meteor.Error(500, "Entity not found, aboring")
      entIns = {}
      entIns.entId = ent._id
      entIns.parentFlowId = flowInsId
      entIns.type = ent.name
      # установить статус сущности
      entIns.state = startTask.stateAfterThisTask
      EntitiesIns.insert(entIns)
    return flowInsId

  "completeTask": (dataObject) ->
    flowIns = FlowsIns.findOne({_id: dataObject.flowInsId})
    if not flowIns?
      throw new Meteor.Error(500, "No Flow instance found, aboring")
    # изменить статус задаче
    TasksIns.update({_id: dataObject._id}, {$set: {state: "completed"}})
    # найти следующую задачу
    for nextPos in dataObject.nextPos
      nextTask = TasksIns.findOne({flowInsId: dataObject.flowInsId, pos: nextPos})
      if not nextTask?
        throw new Meteor.Error(500, "No next task found! Aboring")
      # изменить ей статус и указатель на предыдущую задачу
      TasksIns.update({_id: nextTask._id}, {$set: {state: "current", prevPos: dataObject.pos}})
      # изменить статус и проставить поля сущности, если она есть
      entIns = EntitiesIns.findOne({parentFlowId: flowIns._id})
      if entIns?
        console.log dataObject
        newState = dataObject.stateAfterThisTask
        console.log "newState:", newState
        if newState? and newState != ""
          EntitiesIns.update({_id: entIns._id}, {$set: {state: newState}})
        # изменить другие поля, если они есть
        if dataObject.setFields?
          for field in dataObject.setFields
            $set = {};
            $set[field.name] = field.value;
            EntitiesIns.update({_id: entIns._id}, { $set: $set });

      # если это встроенный подпроцесс ..
      if nextTask.type == "embeddedFlow"
        # найти flow
        flow = Flows.findOne({name: nextTask.subFlowName})
        if not flow?
          throw new Meteor.Error(500, "No subprocess found! Aboring")
        # запустить его
        flow.parentTaskInsId = nextTask._id
        embeddedFlowId = Meteor.call "runFlow", flow
        # записать в текущую задачу id дочернего процесса
        TasksIns.update({_id: nextTask._id}, {$set: {embeddedFlowId: embeddedFlowId}})
      # если это и так последняя задача - завершить процесс целиком
      if nextTask.type == "end"
        FlowsIns.update({_id: flowIns._id}, {$set:{state: "finished"}})
        # если это дочерний вложенный процесс - то завершить родительскую задачу
        if flowIns.parentTaskInsId?
          Meteor.call "completeTask", TasksIns.findOne({_id: flowIns.parentTaskInsId}), (error, result) ->
            if error
              console.log "error", error

  "stepBack": (dataObject) ->
    # текущую задачу сделать новой
    TasksIns.update({_id: dataObject._id}, {$set: {state: "new"}})
    # предыдущую задачу сделать текущей
    prevTask = TasksIns.findOne({flowInsId: dataObject.flowInsId, pos: dataObject.prevPos})
    if not prevTask?
      throw new Meteor.Error(500, "No prev task found! Aboring")
    # изменить ей статус
    TasksIns.update({_id: prevTask._id}, {$set: {state: "current"}})
    # если был запущен дочерний процесс - отменить его
    flowIns = FlowsIns.findOne({_id: dataObject.flowInsId})
    if flowIns.parentTaskInsId?
      Meteor.call "cancelFlowIns", TasksIns.findOne({_id: flowIns.parentTaskInsId}), (error, result) ->
        if error
          console.log "error", error
    # TODO изменить статус и поля обратно

  "cancelFlowIns": (dataObject) ->
    # изменить статус процесса
    FlowsIns.update({_id: dataObject._id}, {$set: {state: "cancelled"}})
    # если были родительские задачи - сделать "шаг назад"
    flowIns = FlowsIns.findOne({_id: dataObject._id})
    if flowIns.parentTaskInsId?
      Meteor.call "stepBack", TasksIns.findOne({_id: flowIns.parentTaskInsId}), (error, result) ->
        if error
          console.log "error", error

  "getAllPossibleFieldsForEntity": (entityName) ->
    map = ->
      for key in this
        emit(key, null)
    reduce = (key, stuff) ->
      null
    EntitiesIns.mapReduce map, reduce, {out: "entitiesIns_keys", verbose: true}, (err, res)->
        console.dir res.stats # statistics object for running mapReduce
        console.log err
        console.log res

  "addTaskBefore": (task) ->
    console.log "starting addTaskBefore:", task
    tasks = Tasks.find({flowName: task.flowName}).fetch()
    console.log "tasks:", tasks
    # найти максимальную позицию
    maxPos = parseInt(_.max(tasks, (task) -> task.pos).pos)
    # добавить новую со ссылкой на следующую
    newTask = {}
    newTask.nextPos = []
    newTask.nextPos.push task.pos
    newTask.flowName = task.flowName
    newTask.pos = maxPos + 1
    newTask.type = "task"
    newTask.role = task.role
    newTask.editMode = true
    newTaskId = Tasks.insert newTask
    console.log "newTaskId:",newTaskId
    for eachTask in tasks
      console.log "iterating thru:", eachTask
      # найти каждую ссылающуюся задачу
      if eachTask.nextPos?
        if _.contains(eachTask.nextPos, task.pos)
          newPos = _.without(eachTask.nextPos, task.pos)
          newPos.push newTask.pos
          Tasks.update({_id: eachTask._id}, {$set: {nextPos: newPos}})
      # найти каждое ссылающееся решение
      if eachTask.decisions?
        for decision in eachTask.decisions
          if _.contains(decision.nextPos, task.pos)
            newPos = _.without(decision.nextPos, task.pos)
            newPos.push newTask.pos
            Tasks.update({_id: eachTask._id, "decisions.id": decision.id}, {$set: {"decisions.$.nextPos": newPos}})

  "saveEditedTask": (task, editMode) ->
    Tasks.update({_id: task._id}, {$set: {
      name: task.name,
      instructions: task.instructions
      editMode: editMode
      }})

  "startEditingTask": (task) ->
    Tasks.update({_id: task._id}, {$set: {editMode: true}})

  "deleteTask": (task) ->
    tasks = Tasks.find({flowName: task.flowName}).fetch()
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
        Tasks.update({_id: eachTask._id}, {$set: {"nextPos": newPos}})
      # найти каждое ссылающееся решение
      if eachTask.decisions?
        for decision in eachTask.decisions
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
    hasLoops = willHaveLoops(Tasks.find({flowName: sourceTask.flowName}).fetch(), {sourcePos: sourceTask.pos, targetPos: targetTask.pos})
    console.log "hasLoops:", hasLoops
    if hasLoops
      throw new Meteor.Error 500, "Loops will be made, aboring"
    newPos = _.without(sourceTask.nextPos, targetTask.pos)
    newPos.push targetTask.pos
    console.log "new nextPos:", newPos
    Tasks.update({_id: sourceTask._id}, {$set: {"nextPos": newPos}})

  "removeTaskConnection": (sourceId, destinationId) ->
    sourceTask = Tasks.findOne({_id: sourceId})
    destTask = Tasks.findOne({_id: destinationId})
    Tasks.update({_id: sourceId}, {$set: {nextPos: _.without(sourceTask.nextPos, destTask.pos)}})

  "addDecision": (task, newDecisionName) ->
    newDecision = {}
    newDecision.name = newDecisionName
    newDecision.id = uuid.v4()
    endTask = Tasks.findOne({flowName: task.flowName, type: "end"})
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
    Tasks.update({_id: dataObject.taskId, "decisions.id": dataObject.decisionId}, {$set: {"decisions.$.nextPos": newPos}})

@willHaveLoops = (tasks, proposedConnection) ->
  # proposedConnection = {sourcePos: pos1, targetPos: pos2, sourceDecisionId: id1, targetDecisionPos: pos}
  console.log "tasks:", tasks
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
