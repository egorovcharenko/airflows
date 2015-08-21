
Template.execute.events
	'click #delete-flow-button': (event, template) ->
		Meteor.call "deleteFlow", {flowId: @_id}, (error, result) ->
			if error
				Materialize.toast error.reason, 4000
