Template.entitiesTable.helpers
  getUser: ->
    user = Meteor.users.findOne(this.createdBy)
    return user
  getFields: ->
    entity = Entities.findOne({name: Router.current().params.type})
    result = [];
    if entity.fieldsToShow?
      for field in entity.fieldsToShow
        result.push field
    return result
  getFieldValues: ->
    entity = Entities.findOne({name: this.type})
    result = [];
    if entity.fieldsToShow?
      for field in entity.fieldsToShow
        res = {}
        res.value = this[field.name]
        result.push res
    return result
Template.registerHelper "prettifyDate", (timestamp) ->
    #return new Date(timestamp).toString('dd-MM-yyyy')
    moment.locale('ru');
    moment(new Date(timestamp)).fromNow()
