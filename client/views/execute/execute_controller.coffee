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
    groups = FlowGroups.find({}, {sort: {name:1}}).fetch()
    for group in groups
      group.flows = Flows.find({groupId: group._id}, {sort: {prettyName:1}}).fetch()
    #console.log "groups:", groups
    return groups
)
