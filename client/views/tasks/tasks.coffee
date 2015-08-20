Template.tasks.helpers
	hasNoTasks: ->
		#console.log "this:", this
		this.count() == 0
