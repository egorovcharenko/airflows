Meteor.methods
  "addNewRole": (data) ->
    accountId = Meteor.user().profile.accountId
    newRole = {
      id: uuid.v4()
      prettyName: data.roleName
      users: []
      accountId: accountId
    }
    Roles.insert(newRole)

  "addNewUserToRole": (data) ->
    accountId = Meteor.user().profile.accountId
    if Roles.find({_id: data.roleId, 'users.id': data.newUserId}).count() > 0
      throw new Meteor.Error 500, "Пользователь уже добавлен к роли"
    else
      Roles.update({_id: data.roleId, accountId: accountId}, {$push: {users: {id: data.newUserId}}})

  "deleteRole": (data) ->
    accountId = Meteor.user().profile.accountId
    # найти название роли
    roleId = Roles.findOne({_id: data.roleId, accountId: accountId}).id
    console.log "roleId:", roleId
    # убрать роль из всех задач
    console.log Tasks.update({roleId: roleId, accountId: accountId}, {$set: {roleId: "unassigned"}}, {multi: true})
    # удалить роль
    console.log Roles.remove({_id: data.roleId, accountId: accountId})

  "detachUserFromRole": (data) ->
    accountId = Meteor.user().profile.accountId
    Roles.update({_id: data.roleId, accountId: accountId}, {$pull: {users: {id: data.userId}}}, {multi: true})
