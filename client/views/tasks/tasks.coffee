Template.tasks.helpers
	hasNoTasks: ->
		#console.log "this:", this
		this.currentFlows.length == 0
