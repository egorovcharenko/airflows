@DrawFlowController = RouteController.extend(
  template: 'drawFlow'
  loadingTemplate: 'loading'
  action : ->
    if this.ready()
      this.render()
  waitOn: ->
    flowId = @params.flowId
    [
      Meteor.subscribe('flow', flowId)
    ]
  data: ->
    flow = Flows.findOne({_id: @params.flowId})
    # найти все роли
    totalTasksCount = Tasks.find({}).count()
    #console.log "total tasks count:", totalTasksCount
    if totalTasksCount == 0
      return null
    roles = _.without(_.uniq(Tasks.find({}).map (x) ->
      x.role), "")
    # задачи - возвращаем накачанный данными массив задач
    tasks = Tasks.find({flowName: flow.name}).fetch()
    startTask = _.findWhere(tasks, {type: "start"})
    params = {}

    lanes = {}
    for laneName in roles
      lanes[laneName] = {}

    rows = []
    params.matrix = {}
    params.maxX = 1
    params.maxY = 1

    # go!
    resetPassed(tasks)
    setWidth(tasks, startTask, params)
    #console.log "tasks after setWidth:", tasks

    startTask.x = 0
    startTask.y = 0
    resetPassed2(tasks)
    assignCoordinates(tasks, startTask, params, rows)
    #console.log "params.matrix:", params.matrix

    # обрабатываем бесхозные задачи
    # находим такую задачу
    parentlessTasks = _.where(tasks, {passed: false})
    console.log "parentlessTasks:", parentlessTasks
    for plTask in parentlessTasks
      # находим совсем безродительскую задачу
      isReallyParentless = true
      for task in tasks
        if task.decisions?
          for decision in task.decisions
            for nextPos in decision.nextPos
              if nextPos == plTask.pos
                isReallyParentless = false
        else
          for nextPos in task.nextPos
            if nextPos == plTask.pos
              isReallyParentless = false
      if not isReallyParentless
        continue
      if plTask.passed
        continue
      if plTask.type == "end"
        continue
      # устанавливаем ей координаты, следующие за предыдущими задачами
      console.log "current maxX:", params.maxX
      plTask.x = params.maxX + 1
      plTask.y = 0
      # запускаем ее обработку
      setWidth(tasks, plTask, params)
      #console.log "tasks after setWidth:", tasks
      resetPassed2(tasks)
      assignCoordinates(tasks, plTask, params, rows)
      #console.log "params.matrix:", params.matrix

    console.log "tasks after setWidth:", tasks
    console.log "params.matrix:", params.matrix

    rows = makeTableFromCoordinates(tasks,params)
    rows.push []
    rows[params.maxY + 1][0] = {task: _.findWhere(tasks, {type: "end"})}
    params.maxY++

    #console.log "rows:", rows

    data = {}
    data.roles = roles
    data.params = params
    data.startTask = startTask
    data.rows = rows
    data.tasks = tasks
    return data
)
resetPassed = (tasks) ->
  for task in tasks
    task.passed = false

resetPassed2 = (tasks) ->
  for task in tasks
    task.passed2 = false

setWidth = (tasks, task, params) ->
  if task.type == "end"
    task.width = 1
    return 1
  task.passed = true
  # есть разветвления?
  if task.decisions?
    decisionsCount = task.decisions.length
    resultingWidth = 0
    for decision in task.decisions
      for nextPos in decision.nextPos
        decisionTask = _.findWhere(tasks, {pos: nextPos})
        if decisionTask.passed
          continue
        if decisionTask.type == "end"
          decisionTask.width = 1
          continue
        else
          taskWidth = setWidth(tasks, decisionTask, params)
          decisionTask.width = taskWidth
          resultingWidth += taskWidth
    task.width = resultingWidth
    return resultingWidth
  else
    # находим следующую задачу
    resultingWidth = 0
    for nextPos in task.nextPos
      nextTask = _.findWhere(tasks, {pos: nextPos})
      taskWidth = setWidth(tasks, nextTask, params)
      task.width = taskWidth
      resultingWidth += taskWidth
    task.width = resultingWidth
    return resultingWidth

# присвоить всем дочерним задачам координаты
assignCoordinates = (tasks, task, params) ->
  console.log "Start assignCoordinates, task:", task
  if task.passed2 == true
    return
  task.passed2 = true
  if task.type != "end"
    params.matrix["#{task.x}-#{task.y}"] = task
  else
    return
  # есть решения?
  if task.decisions?
    shift = 0
    # добавить блок предварительных данных
    if not task.preData?
      task.preData = {}
    # добавить в него данные по решению
    task.preData.decisions = task.decisions
    for decision in task.decisions
      # находим следующую задачу
      for nextPos in decision.nextPos
        decisionTask = _.findWhere(tasks, {pos: nextPos})
        if decisionTask.passed2
          params.maxX = Math.max(params.maxX, task.x)
          params.maxY = Math.max(params.maxY, task.y)
          continue
        else
          # if decisionTask.type == "end"
          #   continue
          # присвоить задаче координаты
          decisionTask.x = task.x + shift
          decisionTask.y = task.y + 1
          shift++
          params.maxX = Math.max(params.maxX, decisionTask.x)
          params.maxY = Math.max(params.maxY, decisionTask.y)

          console.log "decisiontask.name:#{decisionTask.name}, x:#{decisionTask.x}, y:#{decisionTask.y} shift:#{shift}, maxX:#{params.maxX}, maxY:#{params.maxY}"

          assignCoordinates(tasks, decisionTask, params)
    return
  else
    shift = 0
    #console.log "task.nextPos.length:", task.nextPos.length
    # находим следующую задачу
    for nextPos in task.nextPos
      #console.log "nextPos:", nextPos
      nextTask = _.findWhere(tasks, {pos: nextPos})
      if nextTask.passed2
        continue
      else
        if nextTask.type == "end"
          continue
        # вычислить координаты
        nextTask.x = task.x + shift
        nextTask.y = task.y + 1
        shift++
        params.maxX = Math.max(params.maxX, nextTask.x)
        params.maxY = Math.max(params.maxY, nextTask.y)

        console.log "task.name:#{nextTask.name}, x:#{nextTask.x}, y:#{nextTask.y} shift:#{shift}, maxX:#{params.maxX}, maxY:#{params.maxY}"

        # рекурсивно проставить всем задачам координаты
        assignCoordinates(tasks, nextTask, params)

makeTableFromCoordinates = (tasks, params) ->
  rows = []
  console.log "params.maxX:",params.maxX
  console.log "params.maxY:",params.maxY
  for j in [0..params.maxY]
    rows[j] = []
    for i in [0..params.maxX]
      task = params.matrix["#{i}-#{j}"]
      if task?
        rows[j][i] = {task: task}
      else
        rows[j][i] = {}
  return rows
