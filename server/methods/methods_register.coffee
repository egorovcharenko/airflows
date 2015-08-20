Meteor.methods
  "createUserAndAccount": (data) ->
    console.log "data:", data
    #existinAccountCount = Meteor.users.find({'accountId': data.register_account_name}).count()
    existinAccountCountInCol = AccountsColl.find({name: data.register_account_name}).count()
    if existinAccountCountInCol > 0
      throw new Meteor.Error 500, 'Аккаунт с таким именем уже существует'
    newAccount = {
      name: data.register_account_name
      createdDate: new Date()
    }
    accountId = AccountsColl.insert newAccount
    userId = Accounts.createUser {
      email: data.email
      password: data.password
      profile: { name: data.profile.name, accountId: accountId }
    }
    # создать нулевую роль
    unassignedRole = {
      "accountId": accountId,
      "id": "unassigned",
      "prettyName": "Без исполнителя",
      "users" : []
    }
    Roles.insert unassignedRole
    return true
  "sendInvitation": (data) ->
    console.log "sendInvitation started, data:", data
    # сгенерировать токен
    invitation = {
      token: uuid.v4()
      accountId: Meteor.user().profile.accountId
      accountName: data.register_account_name
      email: data.inviteEmail
    }
    console.log Invitations.insert invitation

    # отправить емейл
    this.unblock()
    try
      result = Mandrill.messages.sendTemplate
        template_name: "airflows-invitation"
        template_content: [
          {
            name: 'token'
            content: invitation.token
          }
        ]
        message:
          to: [email: data.inviteEmail]
          global_merge_vars: [
            {
              name: 'token'
              content: invitation.token
            }
          ]
      console.log "result:", result
      return true
    catch e
      console.log "error:", e

  "createUserWithInvitation": (data) ->
    console.log "createUserWithInvitation started, data:", data
    # проверить, не использован ли токен
    token = Invitations.findOne({token: data.inviteToken})
    if not token?
      throw new Meteor.Error 500, "Не найдено приглашение. Если вы уже использовали приглашение, попробуйте запросить его еще раз."
    # создать юзера, привязав к аккаунту
    Accounts.createUser {
      email: data.email
      password: data.password
      profile: { name: data.profile.name, accountId: token.accountId}
    }
    # удалить токен
    Invitations.remove({token: data.inviteToken})
    return true
