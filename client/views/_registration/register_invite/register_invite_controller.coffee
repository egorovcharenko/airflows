@RegisterInviteController = RouteController.extend(
  template: 'RegisterInvite'
  data: ->
    { token: @params.token }
)
