@ExecuteController = RouteController.extend(
  template: 'Execute'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe('allFlowGroups')
      ]
  onBeforeAction: ->
    @next()
    return
  data: ->
    result = {}
    groups = FlowGroups.find({}).fetch()
    for group in groups
      group.flows = Flows.find({groupId: group._id}).fetch()
    console.log "groups:", groups
    return groups
)
