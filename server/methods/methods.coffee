Meteor.methods
  "getAllPossibleFieldsForEntity": (entityName) ->
    map = ->
      for key in this
        emit(key, null)
    reduce = (key, stuff) ->
      null
    EntitiesIns.mapReduce map, reduce, {out: "entitiesIns_keys", verbose: true}, (err, res)->
        console.dir res.stats # statistics object for running mapReduce
        console.log err
        console.log res

# @removeDuplicatesInNextPos = (task)->
#   if task.decisions?
#     for decision in task.decisions
#       decision.nextPos = _.uniq(decision.nextPos)
#   else
#     task.nextPos = _.uniq(task.nextPos)
#   Tasks.save(task)
