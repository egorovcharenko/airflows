@EntitiesTableController = RouteController.extend(
  template: 'entitiesTable'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe 'allEntities'
        Meteor.subscribe "topEntitiesIns", @params.type, 500
      ]
  data: ->
    data = {}
    data.ent = Entities.find({}, {deleted: {$ne: true}})
    data.entIns = EntitiesIns.find()
    data.currentEntity = Entities.find({name: @params.type})
    console.log "EntitiesTableController data finished"
    return data
)
