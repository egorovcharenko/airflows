Meteor.publish "allFlows", (args) ->
  currentUser = Meteor.users.findOne({_id: this.userId})
  Flows.find({accountId: currentUser.profile.accountId})

Meteor.publishComposite 'allFlowGroups', ->
  {
    find: ->
      currentUser = Meteor.users.findOne({_id: this.userId})
      FlowGroups.find({accountId: currentUser.profile.accountId})
    children: [
      {
        find: (group) ->
          Flows.find({groupId: group._id, deleted: {$ne: true}})
        children: [
          {
            find: (flow) ->
              Entities.find({name: flow.entityName})
          }
        ]
      }
    ]
  }

Meteor.publishComposite 'runningTasks', (userId, limit) ->
  {
    find: ->
      currentUser = Meteor.users.findOne({_id: this.userId})
      FlowsIns.find({ state: "running", accountId: currentUser.profile.accountId})
    children: [
      {
        find: (flow) ->
          TasksIns.find({flowInsId: flow._id})
      },
      {
        find: (flowIns) ->
          EntitiesIns.find({parentFlowId: flowIns._id})
      }
    ]
  }

Meteor.publish "allUsers", ->
  currentUser = Meteor.users.findOne({_id: this.userId})
  Meteor.users.find({'profile.accountId': currentUser.profile.accountId})

Meteor.publish "allEntities", (args) ->
  currentUser = Meteor.users.findOne({_id: this.userId})
  Entities.find({accountId: currentUser.profile.accountId}, deleted: {$ne: true})

Meteor.publish "allInvitations", ->
  currentUser = Meteor.users.findOne({_id: this.userId})
  result = Invitations.find({accountId: currentUser.profile.accountId})
  #console.log "result:", result.fetch()
  result

Meteor.publish "demoFlow", ->
  Flows.find({accountId: "demoAccount", id: "demoFlow"})

Meteor.publishComposite "demoFlowIns",  ->
  {
    find: ->
      # запустить процесс
      demoFlowDO = {
        _id: Flows.findOne({
          accountId: "demoAccount"
          id: "demoFlow"
          })._id
        id: "demoFlow"
      }
      flowInsId = Meteor.call "runFlow", demoFlowDO
      FlowsIns.find({_id: flowInsId, accountId: "demoAccount"})
    children: [
      {
        find: (flowIns) ->
          result = TasksIns.find({flowInsId: flowIns._id})
          #console.log "result:", result.fetch()
          return result
      }
    ]
  }

Meteor.publish "allRoles", (args) ->
  currentUser = Meteor.users.findOne({_id: this.userId})
  Roles.find({accountId: currentUser.profile.accountId})

Meteor.publishComposite "topEntitiesIns", (type, limit, showCompleted) ->
  {
    find: ->
      currentUser = Meteor.users.findOne({_id: this.userId})
      console.log "showCompleted:", showCompleted
      if showCompleted == "1"
        return EntitiesIns.find({type: type, accountId: currentUser.profile.accountId}, {limit: limit})
      else
        return EntitiesIns.find({type: type, accountId: currentUser.profile.accountId, state: {$ne: "Завершено"}}, {limit: limit})
    children: [
      {
        find: (entityIns) ->
          TasksIns.find({flowInsId: entityIns.parentFlowId})
      }
    ]
  }

Meteor.publishComposite 'flow', (flowId) ->
  {
    find: ->
      currentUser = Meteor.users.findOne({_id: this.userId})
      result = Flows.find { _id: flowId, accountId: currentUser.profile.accountId}
      console.log "flow:", result.fetch()
      return result
    children: [
      {
        find: (flow) ->
          #console.log "flow:", flow
          tasks = Tasks.find({flowId: flow.id})
          console.log "tasks.count:#{tasks.count()}, flow.id:#{flow.id}, flow._id:#{flow._id}, flowId:#{flowId}"
          return tasks
      },
      {
        find: (flow) ->
          entities = Entities.find({name: flow.entityName})
          return entities
      }
    ]
  }
