Template.execute.events
	'click #run-flow': (event, template) ->
		dataObject = this
		Meteor.call "runFlow", dataObject, (error, result) ->
			if error
				console.log "error", error
			else if result
				Router.go "tasks"
	'click #edit-flow-button': (event, template) ->
		Router.go('drawFlow', {flowId: this._id})
