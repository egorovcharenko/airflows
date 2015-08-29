@EntitiesTableController = RouteController.extend(
  template: 'entitiesTable'
  loadingTemplate: 'loading'
  waitOn: ->
      [
        Meteor.subscribe 'allEntities'
        Meteor.subscribe "topEntitiesIns", @params.type, 500, @params.showCompleted
        Meteor.subscribe "allRoles"
      ]
  data: ->
    data = {}
    data.ent = Entities.find({deleted: {$ne: true}}, {sort: {name:1}})
    data.entIns = EntitiesIns.find({}, {sort: {modifiedAt: -1 }})
    data.currentEntity = Entities.find({name: @params.type})
    console.log "EntitiesTableController data finished"
    return data
)
