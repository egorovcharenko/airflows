@TasksController = RouteController.extend(
  template: 'Tasks'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe('runningTasks')
        Meteor.subscribe('allRoles')
      ]
  onBeforeAction: ->
    @next()
    return
  data: ->
    userRoles=_.map(Roles.find({'users.id': Meteor.userId()}).fetch(), (role) -> role.id )
    myTasksParentFlowsIds = _.map(TasksIns.find({state:"current", roleId: {$in: userRoles}}).fetch(), (task) -> task.flowInsId )
    result = {}
    result.currentFlows = []
    result.futureFlows = []
    # текущие задачи
    currentFlowsIns = FlowsIns.find({_id: {$in: myTasksParentFlowsIds}, parentTaskInsId: {$exists: false}}).fetch()
    currentFlowsInsResult = []
    for flowIns in currentFlowsIns
      # добавить в каждый поток - текущие задачи
      if Meteor.user()?
        tempTasks = TasksIns.find({flowInsId: flowIns._id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}}).fetch()
        flowIns.tasksIns = []
        for taskIns in tempTasks
          if taskIns.delayedUntil?
            if taskIns.delayedUntil <= reactiveDate.now()
              flowIns.tasksIns.push taskIns
          else
            flowIns.tasksIns.push taskIns
        #console.log "flowIns.tasksIns for task #{flowIns.name}:", flowIns.tasksIns
        #console.log "undelayed tasksIns for task #{flowIns.name}:", TasksIns.find({flowInsId: flowIns._id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}}).fetch()
      else
        # demo
        flowIns.tasksIns = TasksIns.find({type: {$nin:["start", "end"]}, state: "current", roleId: {$in: ["role1", "role2"]}}).fetch()
      if flowIns.tasksIns.length > 0
        currentFlowsInsResult.push flowIns
    result.currentFlows = currentFlowsInsResult
    # будующие задачи
    futureFlowsIns = FlowsIns.find({_id: {$in: myTasksParentFlowsIds}, parentTaskInsId: {$exists: false}}).fetch()
    futureFlowsInsResult = []
    for flowIns in futureFlowsIns
      # добавить в каждый поток - текущие задачи
      if Meteor.user()?
        tempTasks = TasksIns.find({flowInsId: flowIns._id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}}).fetch()
        flowIns.tasksIns = []
        for taskIns in tempTasks
          if taskIns.delayedUntil?
            if taskIns.delayedUntil > reactiveDate.now()
              flowIns.tasksIns.push taskIns
        #console.log "FUTURE flowIns.tasksIns for task #{flowIns.name}:", flowIns.tasksIns
        #console.log "FUTURE undelayed tasksIns for task #{flowIns.name}:", TasksIns.find({flowInsId: flowIns._id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}}).fetch()
      else
        # demo
        flowIns.tasksIns = TasksIns.find({type: {$nin:["start", "end"]}, state: "current", roleId: {$in: ["role1", "role2"]}}).fetch()
      if flowIns.tasksIns.length > 0
        futureFlowsInsResult.push flowIns

    result.futureFlows = futureFlowsInsResult
    # if Meteor.user()?
    #   for flow in currentFlowsIns
    #     result.currentFlows.push(TasksIns.find({flowInsId: flow._id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}, $or: [delayedUntil: {$lte: reactiveDate.now()}, delayedUntil: {$exists: false}]}).fetch())
    #     result.futureFlows.push(TasksIns.find({flowInsId: flow._id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}, delayedUntil: {$gt: reactiveDate.now()}}).fetch())
    # else
    #   for flow in currentFlowsIns
    #     result.currentFlows.push(TasksIns.find({type: {$nin:["start", "end"]}, state: "current", roleId: {$in: ["role1", "role2"]}}).fetch())
    #console.log "result:", result
    return result
)
