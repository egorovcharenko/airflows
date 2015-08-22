
Template.execute.events
	'click #delete-flow-button': (event, template) ->
		Meteor.call "deleteFlow", {flowId: @_id}, (error, result) ->
			if error
				Materialize.toast error.reason, 4000
	'click #edit-flow-schedule-button': (event, template) ->
		;
	'click #save-schedule': (event, template) ->
		scheduleJson = {
			enabled: template.find("#enabled-for-#{this._id}").checked
			mon: template.find("#monday-for-#{this._id}").checked
			tue: template.find("#thuesday-for-#{this._id}").checked
			wed: template.find("#wednesday-for-#{this._id}").checked
			thu: template.find("#thursday-for-#{this._id}").checked
			fri: template.find("#friday-for-#{this._id}").checked
			sat: template.find("#saturday-for-#{this._id}").checked
			sun: template.find("#sunday-for-#{this._id}").checked
			hour: parseInt template.find("#hour-select-for-#{this._id}").value
			minutes: parseInt template.find("#minutes-select-for-#{this._id}").value
		}

		Meteor.call "saveSchedule", {schedule: scheduleJson, flowId: this._id}, (error, result) ->
			if error
				Materialize.toast error.reason, 4000
			else
				Materialize.toast("Расписание сохранено", 4000)

Template.executeSingleFlow.helpers
	hourSelected: (hour)->
		if @schedule?
			parseInt(@schedule.hour) == parseInt(hour)
		else
			9 == parseInt(hour)
	minutesSelected: (minutes)->
		if @schedule?
			parseInt(@schedule.minutes) == parseInt(minutes)
		else
			0 == parseInt(minutes)
	scheduleIsEnabled: ->
		if @schedule?
			@schedule.enabled
		else
			false

Template.execute.onRendered ->
	$('.modal-trigger').leanModal();
	$('select').material_select();

Template.executeSingleFlow.onRendered ->
	# console.log "this:", this
	# hours = @schedule.hours
	# $("select.hour-selected").val("val2")
