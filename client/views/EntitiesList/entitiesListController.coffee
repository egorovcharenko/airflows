@EntitiesListController = RouteController.extend(
  template: 'entitiesList'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe('allEntities')
      ]
  data: ->
    data = {}
    data.ent = Entities.find({deleted: {$ne: true}}, {sort: {name:1}})
    console.log "data:", data.ent.fetch()
    return data
)
