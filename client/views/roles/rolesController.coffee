@RolesController = RouteController.extend(
  template: 'roles'
  loadingTemplate: 'loading'
  action : ->
    if this.ready()
      this.render()
  waitOn: ->
    [
      Meteor.subscribe('allRoles')
      Meteor.subscribe('allUsers')
      Meteor.subscribe('allInvitations')
    ]
  data: ->
    roles = Roles.find({id: {$ne: "unassigned"}})
    users = Meteor.users.find({})
    console.log users.fetch()
    data = {
      roles: roles
      users: users
      invitations: Invitations.find({})
    }
    console.log "data.invitations:", data.invitations.fetch()
    return data
)
