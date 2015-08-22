Meteor.methods
  "runFlow": (dataObject) ->
    console.log "runFlow started, data:", dataObject
    flow = Flows.findOne(_id: dataObject._id)
    #console.log "flow:", flow
    accountId = flow.accountId
    # создать экземпляр
    flowInstance = {}
    flowInstance.flowId = dataObject._id
    flowInstance.name = if dataObject.insName then dataObject.insName else flow.prettyName
    console.log "flowInstance.name:", flowInstance.name
    flowInstance.state = "running"
    flowInstance.accountId = accountId
    if dataObject.parentTaskInsId?
      flowInstance.parentTaskInsId = dataObject.parentTaskInsId
    # сохранить
    flowInsId = FlowsIns.insert flowInstance
    # скопировать задания в экземпляры
    tasks = (Tasks.find({flowId: dataObject.id})).fetch()
    #console.log "tasks:", tasks
    for task in tasks
      taskIns = task
      delete taskIns._id
      taskIns.flowInsId = flowInsId
      taskIns.state = "new"
      taskIns.accountId = accountId
      taskInsId = TasksIns.insert taskIns
      if task.type == "start"
        startTask = task
    # установить первую задачу для выполнения
    TasksIns.update({flowInsId: flowInsId, pos: startTask.nextPos[0]}, {$set: {state: "current"}})
    # если привязана сущность - создать ее
    if dataObject.entityName?
      ent = Entities.findOne({name: dataObject.entityName, accountId: accountId})
      if not ent?
        throw new Meteor.Error(500, "Сущность не найдена")
      entIns = {}
      entIns.entId = ent._id
      entIns.accountId = accountId
      entIns.parentFlowId = flowInsId
      entIns.type = ent.name
      entIns.fields = dataObject.fields
      # установить статус сущности
      entIns.state = startTask.stateAfterThisTask
      EntitiesIns.insert(entIns)
    return flowInsId

  'addFlow': (dataObject) ->
    console.log "addFlow started, dataObject:",dataObject
    accountId = Meteor.user().profile.accountId
    # добавить процесс
    newFlow = {
      prettyName: dataObject.flowName,
      description: dataObject.flowDesc,
      id: uuid.v4(),
      accountId: accountId,
      entityName: dataObject.flowName,
      groupId: dataObject.groupId
    }
    newFlowId = Flows.insert newFlow
    # добавить начало и конец
    newStart = {
      flowId: newFlow.id
      pos: "1",
      type: "start"
      roleId: "unassigned"
      nextPos:["999"]
      accountId: accountId
      stateAfterThisTask: "В работе"
    }
    newEnd = {
      flowId: newFlow.id,
      pos: "999",
      type: "end",
      accountId: accountId
    }
    Tasks.insert newStart
    Tasks.insert newEnd
    # добавить новую сущность
    newEntity = {}
    newEntity.accountId = accountId
    newEntity.name = newFlow.prettyName
    Entities.insert newEntity

    console.log "newFlowId:", newFlowId
    result = {flowId: newFlowId}

  'deleteFlow': (dataObject) ->
    console.log "deleteFlow started, dataObject:",dataObject
    # удалить процесс
    Flows.update {_id: dataObject.flowId}, {$set: {deleted: true}}

    # удалить связанны сущности
    flow = Flows.findOne {_id: dataObject.flowId}
    Entities.update {name: flow.entityName}, {$set: {deleted: true}}

  'startSchedulingFlow': (dataObject) ->
    flow = Flows.findOne({_id: dataObject._id})
    reRunAllJobs()
