@TasksController = RouteController.extend(
  template: 'Tasks'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe('runningTasks')
      ]
  onBeforeAction: ->
    @next()
    return
  data: ->
    FlowsIns.find({parentTaskInsId: {$exists: false}})
)
