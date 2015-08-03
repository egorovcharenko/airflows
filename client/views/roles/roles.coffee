Template.roles.events
	'click #add-new-role': (event, template) ->
		newRoleNameTemp = template.find("input#role-name")
		if newRoleNameTemp.value == ""
			Materialize.toast('Название роли не может быть пусто', 4000)
			return
		data = {
			roleName: newRoleNameTemp.value
		}
		Meteor.call "addNewRole", data, (error, result) ->
			if error
				console.log "error", error
			if result
				console.log "success"
			newRoleNameTemp.value = ""
	'click #send-invite': (event, template) ->
		inviteEmail = template.find("input#invite-email").value
		if not isValidEmail inviteEmail
			Materialize.toast('В email содержится ошибка, пожалуйста исправьте', 4000)
			return
		data = {
			inviteEmail: inviteEmail
		}
		$("a#send-invite").addClass('disabled')
		Meteor.call "sendInvitation", data, (error, result) ->
			if error
				Materialize.toast error.reason, 4000
				$("a#send-invite").removeClass('disabled')
			if result
				Materialize.toast "Приглашение успешно отправлено", 4000
				$("a#send-invite").removeClass('disabled')

Template.roles.onRendered ->
	this.autorun ->
		data = Router.current().data()
		Tracker.afterFlush ->
			#$('select').not('#initialized').material_select();
			console.log "============== dom is now created, redrawing"
			#console.log data

@isValidEmail = (email) ->
	re = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i
	return re.test(email)
