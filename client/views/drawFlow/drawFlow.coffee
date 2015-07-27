Template.drawFlow.events
	'click #add-task-before': (event, template) ->
    # добавить новую задачу
		Meteor.call "addTaskBefore", this.task, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
	'click #save-edited-task': (event, template) ->
		task = this.task
		task.name = template.find("input#last_name").value
		task.instructions = template.find("#textarea_instructions").value
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
	notEmpty: ->
		if this.task?
			true
		else
			false
	isStart: ->
		this.task.type == "start"
	isEnd: ->
		this.task.type == "end"
	hasPreData: ->
		this.task.preData?
	hasDecisions: ->
		this.task.decisions?
	maxColspan: ->
		#console.log Router.current().data()
		Router.current().data().params.maxX + 1
	taskConnections: ->
		#console.log "this:", this
		result = []
		if this.task.nextPos?
			for nextPos in this.task.nextPos
				result.push {sourceId: this.task._id, destinationId: Tasks.findOne({pos: nextPos})._id}
		#console.log "result:", result
		result

Template.drawFlow.onRendered ->
	this.autorun ->
		data = Router.current().data()
		Tracker.afterFlush ->
			console.log "============== dom is now created, redrawing"
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
	if task.type == "end"
		return
	if task.decisions?
		i = 0
		for decision in task.decisions
			for nextPos in decision.nextPos
				decisionTask = _.findWhere(tasks, {pos: nextPos})
				connect "decision-#{decision.id}", decisionTask._id, decisionTask.type == "end", fromDecision=true, stubLevel=i++
	else
		for nextPos in task.nextPos
			nextTask = _.findWhere(tasks, {pos: nextPos})
			connect "connection-from-#{task._id}-to-#{nextTask._id}", nextTask._id, nextTask.type=="end", fromDecision=false

connectRecursive = (tasks, task) ->
	if task.type == "end"
		return
	if task.decisions?
		i = 0
		for decision in task.decisions
			for nextPos in decision.nextPos
				decisionTask = _.findWhere(tasks, {pos: nextPos})
				connect "decision-#{decision.id}", decisionTask._id, decisionTask.type == "end", fromDecision=true, stubLevel=i++
				connectRecursive tasks, decisionTask
	else
		for nextPos in task.nextPos
			nextTask = _.findWhere(tasks, {pos: nextPos})
			connect "connection-from-#{task._id}-to-#{nextTask._id}", nextTask._id, nextTask.type=="end", fromDecision=false
			connectRecursive tasks, nextTask

connect = (id1, id2, end, fromDecision, stubLevel) ->
	anchors = []
	if fromDecision
		anchors.push "Right"
	else
		anchors.push "Bottom"
	anchors.push "Top"

	#console.log "connecting '#{id1}' to '#{id2}'"
	jsPlumb.connect {
		source:"#{id1}",
		target:"#{id2}",
		endpoint:["Dot", {radius: 3}], connector:[ "Flowchart", {alwaysRespectStubs:true, midpoint:0.99, stub:10 + stubLevel*5, cornerRadius:2 } ],
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
		re = new RegExp("^new_connection_for_task_(.+)_with_decision_(.+)$","g");
		result = re.exec(connection.sourceId)
		#console.log "result:", result
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
		if task.type == "end"
			continue

		test = $("##{task._id}").length
		if not test
			continue

		#console.log "Making target: #{task._id}"
		instance.makeTarget("#{task._id}", { anchor: [0.6, 1, 0, 1] }, newConnectionEndpoint)

		if task.decisions?
			for decision in task.decisions
				test = $("#new_connection_for_task_#{task._id}_with_decision_#{decision.id}").length
				if not test
					continue
				else
					instance.makeSource("new_connection_for_task_#{task._id}_with_decision_#{decision.id}", { anchor: [0.6, 1, 0, 1] }, newConnectionEndpoint)
		else
			test = $("#new-connection-from-#{task._id}").length
			if not test
				continue
			else
				instance.makeSource("new-connection-from-#{task._id}", { anchor: [0.6, 1, 0, 1] }, newConnectionEndpoint)
