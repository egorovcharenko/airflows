@EntitiesListController = RouteController.extend(
  template: 'entitiesList'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe('allEntities')
      ]
  data: ->
    data = {}
    data.ent = Entities.find()
    return data
)
