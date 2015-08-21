@EntitiesListController = RouteController.extend(
  template: 'entitiesList'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe('allEntities')
      ]
  data: ->
    data = {}
    data.ent = Entities.find({}, deleted: {$ne: true})
    console.log "data:", data.ent.fetch()
    return data
)
