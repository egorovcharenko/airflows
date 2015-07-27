@ExecuteController = RouteController.extend(
  template: 'Execute'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe('allFlows')
      ]
  onBeforeAction: ->
    @next()
    return
  data: ->
    Flows.find()
)
