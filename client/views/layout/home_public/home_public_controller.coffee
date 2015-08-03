@HomePublicController = RouteController.extend(
  template: 'HomePublic'
  waitOn: ->
    [
      Meteor.subscribe "demoFlowIns"#, Session.get "flowInsId"
      Meteor.subscribe "demoFlow"
    ]

  onBeforeAction: ->

    this.next()

  data: ->
    #console.log "all flowsIns:", FlowsIns.find().fetch()
    # найти его экземпляр и вернуть
    myTasksParentFlowsIds = _.map(TasksIns.find({state:"current", roleId: {$in: ["role1"]}}).fetch(), (task) -> task.flowInsId )
    #console.log "myTasksParentFlowsIds:",myTasksParentFlowsIds
    flowsIns = FlowsIns.find({_id: {$in: myTasksParentFlowsIds}, parentTaskInsId: {$exists: false}})
    result = flowsIns
    #console.log "result:", result.fetch()
    return result
)
