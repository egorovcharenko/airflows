pluralize2_arr = (number, forms) ->
  number = Math.abs(number)
  number %= 100
  if (number >= 5 && number <= 20)
    return forms[2]
  number %= 10
  if (number == 1)
    return forms[0]
  if (number >= 2 && number <= 4)
    return forms[1]
  return forms[2]

Template.singleFlowIns.helpers
	isTaskCompleted: ->
		this.state in ["completed"]
	taskTypeIsTask: ->
		#this.type == "task"
		not this.decisions?
	taskTypeIsDecision: ->
		#this.type == "decision"
		this.decisions?
	isTaskNotCurrent: ->
		this.state isnt "current"
	showTask: ->
		if @state isnt "current"
			false
		else
			true
	isTaskIsFirst: ->
	  TasksIns.findOne({flowInsId: @flowInsId, type: "start"}).nextPos == @pos
	isPreend: ->
		@type == "preend"
	logDataContext: (text)->
		console.log text, this
	isEmbeddedFlow: ->
		@type == "embeddedFlow"
	getEmbeddedFlow: ->
		FlowsIns.findOne({_id: @embeddedFlowId})
	hasCurrentTasks: ->
		if Meteor.user()?
			userRoles = _.map(Roles.find({'users.id': Meteor.userId()}).fetch(), (role) -> role.id)
			#console.log "userRoles:",userRoles
			currentTasksCount = TasksIns.find({flowInsId: @_id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}}).count()
			currentTasksCount > 0
		else
			TasksIns.find({type: {$nin:["start", "end"]}, state: "current", roleId: {$in: ["role1", "role2"]}}).count() > 0
	isDemo: ->
		if Meteor.user()?
			false
		else
			true
	isNotDemo: ->
		if Meteor.user()?
			true
		else
			false
	logDataContext: ->
		#console.log "logDataContext:", this
	dataFields: ->
		entIns = EntitiesIns.findOne({parentFlowId: @_id})
		#console.log "entIns:", entIns, ", this:", this
		return entIns.fields
	hasTiming: ->
		this.timing?
	timeLeftObject: ->
		result = {}
		startTime = this.startTime
		now = reactiveDate.now()
		if startTime?
			minutesElapsed = Math.floor((now - startTime) / (1000*60))
			if this.timing?
				if not isNaN(this.timing)
					minutesLeft = this.timing - minutesElapsed
		if minutesLeft?
			if minutesLeft >= 0
				result.string = "Осталось #{minutesLeft} #{pluralize2_arr minutesLeft, ["минута","минуты", "минут"]}"
				result.overdue = false
			else
				result.string = "Просрочено на #{-minutesLeft} #{pluralize2_arr minutesLeft, ["минута","минуты", "минут"]}"
				result.overdue = true
		else
			result.string =  ""
			result.overdue = false
		return result

Template.singleFlowIns.events
	"click #task-completed": (event, template) ->
		dataObject = this
		dataObject.fields = []
		allFields = template.findAll("input.edit-data-field")
		for field in allFields
			dataObject.fields.push({
				name: field.dataset.fieldName,
				value: field.value
				})
		#console.log "dataObject.fields:", dataObject.fields
		Meteor.call "completeTask", dataObject, (error, result) ->
			if error
				console.log "error", error
			if result
				;
	"click #decision-button": (event, template) ->
		dataObject = this
		dataObject.flowInsId = event.target.dataset.flowinsid
		dataObject._id = event.target.dataset.taskid
		console.log "dataObject._id:", dataObject._id, ", dataObject:", dataObject
		dataObject.pos = TasksIns.findOne({_id: dataObject._id}).pos
		Meteor.call "completeTask", dataObject, (error, result) ->
			if error
				console.log "error", error
	"click #back-button": (event, template) ->
		dataObject = this # task
		dataObject.flowsInsId = this.flowId
		Meteor.call "stepBack", dataObject, (error, result) ->
			if error
				console.log "error", error
	"click #cancel-button": (event, template) ->
		dataObject = this # flow
		Meteor.call "cancelFlowIns", dataObject, (error, result) ->
			if error
				console.log "error", error

Template.singleFlowInsDataField.events
	"click .save-data-field-button": (event, template) ->
		newValue = template.find("input.edit-data-field").value
		console.log "newValue:", newValue
		Meteor.call "updateEntityInsDataField", {flowInsId: Template.parentData(1)._id, fieldName: @name, newValue: newValue}, (error, result) ->
			if error
				Materialize.toast error.reason, 4000
			else
				Materialize.toast "Сохранено", 4000
