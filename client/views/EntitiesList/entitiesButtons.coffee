Template.entitiesButtons.events
	'click #gotoEntityType': (event, template) ->
		console.log "entity name:", this.name
		Router.go('entitiesTable', {type: this.name})
