Template.singleRole.events
  'click #add-new-user-to-role': (event, template) ->
    newUserId = template.find("select").value
    if newUserId == "0000"
      return
    data = {
      roleId: this._id
      newUserId: newUserId
    }
    console.log "data:", data
    Meteor.call "addNewUserToRole", data, (error, result) ->
      if error
        console.log "error", error
        Materialize.toast error.reason, 4000
      if result
        console.log "success"
  'click #delete_role': (event, template) ->
    console.log "delete role"
    data = {
      roleId: this._id
    }
    Meteor.call "deleteRole", data, (error, result) ->
      if error
        console.log "error", error
        Materialize.toast error.reason, 4000
      if result
        Materialize.toast "Роль удалена", 4000
  'click #detach_user_from_role': (event, template) ->
    console.log "22"
    data = {
      roleId: event.target.dataset.roleId
      userId: this.id
    }
    console.log data
    Meteor.call "detachUserFromRole", data, (error, result) ->
      if error
        console.log "error", error
        Materialize.toast error.reason, 4000
      if result
        Materialize.toast "Человек отвязан от роли", 4000

Template.singleRole.helpers
  usernameFor: (id)->
    Meteor.users.findOne({_id: id}).profile.name

Template.singleRole.onRendered ->
  temp = this.find('select')
  #console.log temp
  $(temp).material_select();
  #$('select').not('#initialized').material_select();
