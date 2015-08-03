
Template.singleFlowIns.helpers
	subTasks: ->
		if Meteor.user()?
			userRoles = _.map(Roles.find({'users.id': Meteor.userId()}).fetch(), (role) -> role.id)
			#console.log "userRoles:",userRoles
			TasksIns.find({flowInsId: @_id, type: {$nin:["start", "end"]}, state: "current", roleId: {$in: userRoles}})
		else

			result = TasksIns.find({type: {$nin:["start", "end"]}, state: "current", roleId: {$in: ["role1", "role2"]}})
			#console.log "flowInsId:",@_id, ", result:", result.fetch()
			return result
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
Template.singleFlowIns.events
	"click #task-completed": (event, template) ->
		dataObject = this
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
		Meteor.call "stepBack", dataObject, (error, result) ->
			if error
				console.log "error", error
	"click #cancel-button": (event, template) ->
		dataObject = this # flow
		Meteor.call "cancelFlowIns", dataObject, (error, result) ->
			if error
				console.log "error", error
