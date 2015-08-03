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

	'click #add-new-flow': (event, template) ->
		dataObject = {}
		dataObject.flowName = template.find("#newFlowName").value
		dataObject.flowDesc = template.find("#textarea_desc").value

		Meteor.call "addFlow", dataObject, (error, result) ->
			if error
				console.log "error", error
				Materialize.toast('Ошибка при создании процесса:' + error, 4000)
			else
				if result
					Router.go('drawFlow', {flowId: result.flowId})
				else
					Materialize.toast('Ошибка при создании процесса: не вернулся результат', 4000)
