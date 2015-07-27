Template.entitiesButtons.events
	'click #gotoEntityType': (event, template) ->
    Router.go('entitiesTable', {type: this.name})
