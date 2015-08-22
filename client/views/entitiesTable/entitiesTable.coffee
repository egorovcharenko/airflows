Template.entitiesTable.helpers
  getUser: ->
    user = Meteor.users.findOne(this.createdBy)
    return user
  getFields: ->
    entity = Entities.findOne({name: Router.current().params.type})
    result = [];
    if entity.fields?
      for field in entity.fields
        result.push field
    return result
  getFieldValues: ->
    result = [];
    if @fields?
      for field in @fields
        res = {}
        res.value = field.value
        result.push res
    return result
  currentTask: ->
    #userRoles = _.map(Roles.find({'users.id': Meteor.userId()}).fetch(), (role) -> role.id)
    #console.log "userRoles:",userRoles
    result = ""
    currentTasks = TasksIns.find({flowInsId: @parentFlowId, type: {$nin:["start", "end"]}, state: "current"})
    for task in currentTasks.fetch()
      str = "#{task.name}: #{task.roleId}"
      if result == ""
        result = str
      else
        result = result + "<br/>" + str
    #console.log "result:", result
    return result
Template.entitiesTable.events
	'click #show-completed-button': (event, template) ->
    Router.go('entitiesTable', {type: Router.current().params.type, showCompleted:1})

Template.registerHelper "prettifyDate", (timestamp) ->
    #return new Date(timestamp).toString('dd-MM-yyyy')
    moment.locale('ru');
    moment(new Date(timestamp)).format('DD.MM.YYYY в HH:mm')
