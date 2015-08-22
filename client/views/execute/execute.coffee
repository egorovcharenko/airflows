Template.executeSingleFlow.events
	'click #run-flow': (event, template) ->
		dataObject = this
		# добавить значения полей
		dataObject.fields = []
		allFields = template.findAll("input.enter-data-field")
		for field in allFields
			dataObject.fields.push({
				name: field.dataset.fieldName,
				value: field.value
				})
			field.value = ""
		#console.log "dataObject.fields:", dataObject.fields
		Meteor.call "runFlow", dataObject, (error, result) ->
			if error
				console.log "error", error
			else if result
				Materialize.toast "Процесс успешно запущен", 4000
				;#Router.go "tasks"
	'click #edit-flow-button': (event, template) ->
		Router.go('drawFlow', {flowId: this._id})


Template.execute.helpers
	hasNoFlows: ->
		@flows.length == 0

Template.executeAddNewFlow.events
	'click #add-new-flow': (event, template) ->
		dataObject = {}
		dataObject.flowName = template.find("#newFlowName").value
		dataObject.flowDesc = template.find("#textarea_desc").value
		dataObject.groupId = @_id

		Meteor.call "addFlow", dataObject, (error, result) ->
			if error
				Materialize.toast error.reason, 4000
			else
				if result
					Router.go('drawFlow', {flowId: result.flowId})
				else
					Materialize.toast('Ошибка при создании процесса: не вернулся результат', 4000)

Template.execute.events
	'click #add-new-flow-group': (event, template) ->
		groupName = template.find("#newFlowGroupName").value
		if groupName == ""
			Materialize.toast "Название группы не может быть пустым"
			return
		Meteor.call "addNewFlowGroup", {groupName: groupName}, (error, result) ->
			if error
				Materialize.toast error.reason, 4000
			else
				template.find("#newFlowGroupName").value = ""

	'click #delete-flow-group': (event, template) ->
		Meteor.call "deleteFlowGroup", {groupName: this.name}, (error, result) ->
			if error
				Materialize.toast error.reason, 4000

Template.executeSingleFlow.helpers
	dataFields: ->
		# находим сущность
		entity = Entities.findOne({name: this.entityName})
		# возвращаем ее поля
		if entity?
			if entity.fields?
				return entity.fields
		return null
		#console.log "this:", this

Template.execute.onRendered ->
	this.autorun ->
		data = Router.current().data()
		Tracker.afterFlush ->
		  $(document).ready ->
		    $('.collapsible').collapsible
		      accordion : false # A setting that changes the collapsible behavior to expandable instead of the default accordion style
