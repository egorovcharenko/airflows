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
    console.log "myTasksParentFlowsIds:",myTasksParentFlowsIds
    FlowsIns.find({_id: {$in: myTasksParentFlowsIds}, parentTaskInsId: {$exists: false}})
)
