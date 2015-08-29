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
      try
        roleName = Roles.findOne({id: task.roleId}).prettyName
        # тайминг
        startTime = task.startTime
        now = reactiveDate.now()
        if startTime?
          minutesElapsed = Math.floor((now - startTime) / (1000*60))
          if task.timing?
            if not isNaN(task.timing)
              minutesLeft = task.timing - minutesElapsed
      catch e
        console.log "e:", e
        roleName = "(не найдено)"
      console.log "#{now-startTime}, #{now}, #{startTime}, #{minutesElapsed}, #{minutesLeft}, #{task.timing}"
      str = "#{task.name}: #{roleName}"
      if minutesElapsed?
        str = str + ", прошло #{minutesElapsed} минут"
      if minutesLeft?
        str = str + ", осталось #{minutesLeft} минут"
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
