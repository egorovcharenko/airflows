
Template.singleFlowIns.helpers
	subTasks: ->
		TasksIns.find({flowInsId: @_id, type: {$nin:["start", "end"]}})
	isTaskCompleted: ->
		this.state in ["completed"]
	taskTypeIsTask: ->
		this.type == "task"
	taskTypeIsDecision: ->
		this.type == "decision"
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
