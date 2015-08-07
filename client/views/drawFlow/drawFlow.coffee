Template.drawFlow.events
	'click #add-task-before': (event, template) ->
    # добавить новую задачу
		Meteor.call "addTaskBefore", this.task, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #add-task-to-the-right': (event, template) ->
		#console.log "this.task:", this.task
    # добавить новую задачу
		Meteor.call "addTaskToTheSide", this.task, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #add-task-to-the-left': (event, template) ->
    # добавить новую задачу
		Meteor.call "addTaskToTheSide", this.task, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #add-task-after': (event, template) ->
    # добавить новую задачу
		Meteor.call "addTaskAfter", this.task, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #save-edited-task': (event, template) ->
		task = this.task
		inputName = template.find("input#last_name")
		if inputName
			task.name = inputName.value
		inputInstr = template.find("#textarea_instructions")
		if inputInstr
			task.instructions = inputInstr.value
		temp = template.find("select")
		#console.log "temp:", temp
		task.roleId = temp.value
		console.log "task.roleId:",task.roleId
		Meteor.call "saveEditedTask", this.task, false, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #start_editing_task': (task) ->
		Meteor.call "startEditingTask", this.task, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #delete_task': (task) ->
		console.log "deletingTask"
		Meteor.call "deleteTask", this.task, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #remove-connection': (event, template) ->
		console.log "remove-connection, data:", event.target.dataset.source
		Meteor.call "removeTaskConnection", event.target.dataset.source, event.target.dataset.destination, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #add-decision': (event, template) ->
		task = this.task
		decisionText = template.find("input#newDecisionName").value
		if decisionText != ""
			template.find("input#newDecisionName").value = ""
			console.log "decisionText:", decisionText
			Meteor.call "addDecision", task, decisionText, (error, result) ->
				if error
					console.log "error", error
				if result
					console.log "success"
		else Materialize.toast('Текст решения не должен быть пустым', 4000)
	'click #remove-decision' :(event, template) ->
		console.log "remove-decision, data:", event.target.dataset
		Meteor.call "removeTaskDecision", event.target.dataset.taskId, event.target.dataset.decisionId, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"

Template.drawFlow.helpers
	allRoles: ->
		return Roles.find({})
	isRoleSelected: ->
		#console.log "this.id:", this.id
		#console.log "task.roleId:",Template.parentData().task.roleId
		this.id == Template.parentData().task.roleId
	classForSelectedRole: ->
		if this.id == Template.parentData().task.roleId
			return "selected_class"
		else
			return false
	notEmpty: ->
		if this.task?
			true
		else
			false
	isStart: ->
		this.task.type == "start"
	isNotStart: ->
		this.task.type != "start"
	isEnd: ->
		this.task.type == "end"
	isNotEnd: ->
		this.task.type != "end"
	hasPreData: ->
		this.task.preData?
	hasDecisions: ->
		this.task.decisions?
	doesNotHaveDecisions: ->
		not this.task.decisions?
	maxColspan: ->
		#console.log Router.current().data()
		if this.task.type == "end"
			Router.current().data().params.maxX + 1
		else
			1

	taskConnections: ->
		#console.log "this:", this
		getTaskConnections this.task

	hasLeftBorder: ->
		this.hasLeftBorder

	hasRightBorder: ->
		this.hasRightBorder

	debugInfo: ->
		"operator-#{this.task.roleWidth['operator']}<br>
		role2-#{this.task.roleWidth['role2']}<br>
		roleId-#{this.task.roleId}"

	notLastConnection: ->
		connections = getTaskConnections this.task
		console.log "connections:", connections
		console.log "connections result:", connections.length > 1
		connections.length > 1

@getTaskConnections = (task) ->
	result = []
	if task.nextPos?
		for nextPos in task.nextPos
			result.push {sourceId: task._id, destinationId: Tasks.findOne({pos: nextPos})._id}
	#console.log "result:", result
	return result

Template.drawFlow.onRendered ->
	this.autorun ->
		data = Router.current().data()
		Tracker.afterFlush ->
			$('select').material_select();
			#console.log "============== dom is now created, redrawing"
			jsPlumb.setContainer($("#links-container"))
			jsPlumb.detachEveryConnection()
			jsPlumb.deleteEveryEndpoint()
			jsPlumb.setSuspendDrawing(true)
			#jsPlumb.draggable()
			for task in data.tasks
				connectNonRecursive data.tasks, task
			initJsPlumb data.tasks
			jsPlumb.setSuspendDrawing(false, true)

connectNonRecursive = (tasks, task) ->
	stubLevel = 0
	if task.type == "end"
		return
	if task.decisions?

		for decision in task.decisions
			for nextPos in decision.nextPos
				decisionTask = _.findWhere(tasks, {pos: nextPos})
				connect "task_#{task._id}_decision_#{decision.id}", decisionTask._id, decisionTask.type == "end", fromDecision=true, stubLevel=stubLevel++
	else
		for nextPos in task.nextPos
			nextTask = _.findWhere(tasks, {pos: nextPos})
			connect "connection-from-#{task._id}-to-#{nextTask._id}", nextTask._id, nextTask.type=="end", fromDecision=false, stubLevel=stubLevel++

connect = (id1, id2, end, fromDecision, stubLevel) ->
	anchors = []
	if fromDecision
		anchors.push "Right"
	else
		anchors.push "Bottom"
	anchors.push "Top"

	console.log "connecting '#{id1}' to '#{id2}'"
	jsPlumb.connect {
		source:"#{id1}",
		target:"#{id2}",
		endpoint:["Dot", {radius: 3}], connector:[ "Flowchart", {alwaysRespectStubs:true, midpoint: (0.5 + stubLevel * 0.1), stub:5 + stubLevel*5, cornerRadius:2 } ],
		anchors: anchors,
		paintStyle:{ strokeStyle:"black", lineWidth:1 }
	}

initJsPlumb = (tasks)->
	instance = jsPlumb.getInstance(
	  DragOptions:
	    cursor: 'pointer'
	    zIndex: 2000
	  PaintStyle: strokeStyle: '#666'
	  EndpointHoverStyle: fillStyle: 'orange'
	  HoverPaintStyle: strokeStyle: 'orange'
	  EndpointStyle:
	    width: 20
	    height: 16
	    strokeStyle: '#666'
	  Endpoint: 'Rectangle'
	  Anchors: [
	    'TopCenter'
	    'TopCenter'
	  ]
		ConnectionsDetachable:false
		)

	instance.setContainer($("#links-container"));
  # bind to connection/connectionDetached events, and update the list of connections on screen.
	instance.bind 'connection', (info, originalEvent) ->
		;
	instance.bind 'beforeDrop', (connection) ->
		#console.log "connection:", connection
		re = new RegExp("^task_(.+)_decision_(.+)$","g");
		result = re.exec(connection.sourceId)
		console.log "RegExp result:", result
		if result
			#console.log "connection for decision, taskId:#{result[1]}, decisionId:#{result[2]}, targetId:#{connection.targetId}"
			Meteor.call "makeDecisionConnection", { taskId: result[1], decisionId: result[2], targetId: connection.targetId }, (error, result) ->
				if error
					console.log "error", error
				if result
					console.log "connection successful", result
		else
			#console.log "connection from #{info.sourceId} to #{info.targetId}"
			Meteor.call "makeTaskConnection", connection.sourceId, connection.targetId, (error, result) ->
				if error
					console.log "error", error
				if result
					console.log "connection successful", result
		return false

  instance.bind 'connectionDetached', (info, originalEvent) ->
    console.log "connectionDetached"

  instance.bind 'connectionMoved', (info, originalEvent) ->
    #  only remove here, because a 'connection' event is also fired.
    # in a future release of jsplumb this extra connection event will not
    # be fired.
    console.log "connectionMoved"
  instance.bind 'click', (component, originalEvent) ->
    console.log "click"
	# configure some drop options for use by all endpoints.
	exampleDropOptions = { tolerance: 'touch', hoverClass: 'dropHover',activeClass: 'dragActive'}
	newConnectionEndpoint = {
		endpoint: ['Blank', { radius: 11 }],
		paintStyle:{fillStyle: '#222222'},
		isSource: false,
		isTarget: false,
		reattach: false,
		connectorStyle:{lineWidth: 2, strokeStyle:'#222222', dashstyle: '3 2'},
		dropOptions: exampleDropOptions}

	for task in tasks
		#console.log "task:", task

		test = $("##{task._id}").length
		if not test
			continue

		#console.log "Making target: #{task._id}"
		instance.makeTarget("#{task._id}", { anchor: [0.6, 1, 0, 1] }, newConnectionEndpoint)

		if task.type == "end"
			continue

		if task.decisions?
			for decision in task.decisions
				test = $("#task_#{task._id}_decision_#{decision.id}").length
				if not test
					continue
				else
					instance.makeSource("task_#{task._id}_decision_#{decision.id}", { anchor: [0.6, 1, 0, 1] }, newConnectionEndpoint)
		else
			test = $("#new-connection-from-#{task._id}").length
			if not test
				continue
			else
				instance.makeSource("new-connection-from-#{task._id}", { anchor: [0.6, 1, 0, 1] }, newConnectionEndpoint)
