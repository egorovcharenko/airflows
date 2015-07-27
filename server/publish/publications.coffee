Meteor.publish "allFlows", (args) ->
  Flows.find()

Meteor.publishComposite 'runningTasks', (userId, limit) ->
  {
    find: ->
      FlowsIns.find { state: "running"}
    children: [
      {
        find: (flow) ->
          TasksIns.find({flowInsId: flow._id})
      }
    ]
  }

Meteor.publish "allEntities", (args) ->
  Entities.find()

Meteor.publish "topEntitiesIns", (type, limit) ->
  EntitiesIns.find({type: type}, {limit: limit})

Meteor.publishComposite 'flow', (flowId) ->
  {
    find: ->
      Flows.find { _id: flowId}
    children: [
      {
        find: (flow) ->
          console.log "flow:", flow
          tasks = Tasks.find({flowName: flow.name})
          console.log "tasks.count:", tasks.count()
          return tasks
      }
    ]
  }
