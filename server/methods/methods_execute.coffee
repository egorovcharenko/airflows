Meteor.methods
  "completeTask": (dataObject) ->
    flowIns = FlowsIns.findOne({_id: dataObject.flowInsId})
    if not flowIns?
      throw new Meteor.Error(500, "Не найден экземпляр процесса")
    # транзакция
    tx.start("completeTask");
    # изменить статус задаче
    TasksIns.update({_id: dataObject._id}, {$set: {state: "completed"}}, {tx: true})
    # найти следующую задачу
    for nextPos in dataObject.nextPos
      nextTask = TasksIns.findOne({flowInsId: dataObject.flowInsId, pos: nextPos})
      if not nextTask?
        throw new Meteor.Error(500, "Не найдена следующая задача")
      # изменить ей статус и указатель на предыдущую задачу
      TasksIns.update({_id: nextTask._id}, {$set: {state: "current", prevPos: dataObject.pos}}, {tx: true})
      # изменить статус и проставить поля сущности, если она есть
      entIns = EntitiesIns.findOne({parentFlowId: flowIns._id})
      if entIns?
        console.log dataObject
        newState = dataObject.stateAfterThisTask
        console.log "newState:", newState
        if newState? and newState != ""
          EntitiesIns.update({_id: entIns._id}, {$set: {state: newState}}, {tx: true})
        # изменить другие поля, если они есть
        if dataObject.setFields?
          for field in dataObject.setFields
            $set = {};
            $set[field.name] = field.value;
            EntitiesIns.update({_id: entIns._id}, { $set: $set }, {tx: true});

      # если это встроенный подпроцесс ..
      if nextTask.type == "embeddedFlow"
        # найти flow
        flow = Flows.findOne({id: nextTask.subFlowId})
        if not flow?
          throw new Meteor.Error(500, "Подпроцесс не найден")
        # запустить его
        flow.parentTaskInsId = nextTask._id
        embeddedFlowId = Meteor.call "runFlow", flow
        # записать в текущую задачу id дочернего процесса
        TasksIns.update({_id: nextTask._id}, {$set: {embeddedFlowId: embeddedFlowId}}, {tx: true})
      # если это и так последняя задача - завершить процесс целиком
      if nextTask.type == "end"
        FlowsIns.update({_id: flowIns._id}, {$set:{state: "finished"}}, {tx: true})
        if entIns?
          # обновить статус сущности - на завершенную
          EntitiesIns.update({_id: entIns._id}, {$set: {state: "Завершено"}}, {tx: true})
        # если это дочерний вложенный процесс - то завершить родительскую задачу
        if flowIns.parentTaskInsId?
          Meteor.call "completeTask", TasksIns.findOne({_id: flowIns.parentTaskInsId}), (error, result) ->
            if error
              console.log "error:", error
    tx.commit();

  "stepBack": (dataObject) ->
    console.log "stepBack started, data:", dataObject
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

  "updateEntityInsDataField": (dataObject) ->
    console.log "updateEntityInsDataField started, dataObject:", dataObject
    #flowIns = FlowsIns.findOne({_id: dataObject.flowInsId})
    EntitiesIns.update({parentFlowId: dataObject.flowInsId, 'fields.name': dataObject.fieldName}, {$set: {'fields.$.value': dataObject.newValue}})

  "addNewFlowGroup": (dataObject) ->
    console.log "addNewFlowGroup started, dataObject:", dataObject
    accountId = Meteor.user().profile.accountId
    newGroup = {
      accountId: accountId
      name: dataObject.groupName
    }
    FlowGroups.insert newGroup

  "deleteFlowGroup": (dataObject) ->
    console.log "deleteFlowGroup started, dataObject:", dataObject
    FlowGroups.remove {name: dataObject.groupName}

  "saveSchedule": (dataObject) ->
    console.log "saveSchedule started, dataObject:", dataObject
    Flows.update({_id: dataObject.flowId}, {$set: {schedule: dataObject.schedule}})
    # запустить шедулинг процесса
    runSchedulingForFlowId(dataObject.flowId)
