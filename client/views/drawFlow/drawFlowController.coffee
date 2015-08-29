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
      Meteor.subscribe('allRoles')
    ]
  data: ->
    flow = Flows.findOne({_id: @params.flowId})
    totalTasksCount = Tasks.find({}).count()
    #console.log "total tasks count:#{totalTasksCount}, flowId:#{@params.flowId}"
    if totalTasksCount == 0
      console.log "total tasks count = 0"
      return null
    roles = _.without(_.without(_.uniq(Tasks.find({}, {sort: {prettyName: -1}}).map (x) ->
      x.roleId), ""), undefined)
    #console.log "roles:", roles
    # задачи - возвращаем накачанный данными массив задач
    # найти все задачи
    tasks = Tasks.find({flowId: flow.id}).fetch()
    startTask = _.findWhere(tasks, {type: "start"})
    params = {}

    rows = []
    params.matrix = {}
    params.maxX = 0
    params.maxY = 0

    # go!
    resetPassed(tasks)
    setWidth(tasks, startTask, params, roles)
    #console.log "tasks after setWidth:", tasks

    # расчитываем отступы ролей
    roleWidthMax = {}
    rolesOffsets = {}
    returnedRoles = []
    if startTask?
      #roleWidthMax = startTask.roleWidth
      #console.log "roleWidthMax:", roleWidthMax
      currentOffset = 0
      for roleId in roles
        rolesOffsets[roleId] = currentOffset
        roleMaxWidth = 0
        for iterTask in tasks
          if iterTask.roleWidth?
            rWidth = iterTask.roleWidth[roleId]
            roleMaxWidth = Math.max(rWidth, roleMaxWidth)
            roleWidthMax[roleId] = roleMaxWidth
        #console.log "rolesOffsets[#{roleId}] = #{rolesOffsets[roleId]}"
        currentOffset += roleWidthMax[roleId]
        #console.log "Role #{roleId} has width #{roleWidthMax[roleId]}, offset:#{rolesOffsets[roleId]}"
        if roleId?
          roleFound = Roles.findOne({id: roleId})
          if roleFound?
            returnedRoles.push {
              prettyName: roleFound.prettyName
              width: roleWidthMax[roleId]
            }

    startTask.x = 0
    startTask.y = 0
    resetPassed2(tasks)
    assignCoordinates(tasks, startTask, params, roleWidthMax, rolesOffsets)
    #console.log "params.matrix after assignCoordinates:", params.matrix

    # обрабатываем бесхозные задачи
    # находим такую задачу
    parentlessTasks = _.where(tasks, {passed: false})
    #console.log "parentlessTasks:", parentlessTasks
    for plTask in parentlessTasks
      if plTask.type == "end" or plTask.type == "start"
        continue
      # находим совсем безродительскую задачу
      isReallyParentless = true
      for task in tasks
        if task.decisions?
          for decision in task.decisions
            if nextPos?
              for nextPos in decision.nextPos
                if nextPos == plTask.pos
                  isReallyParentless = false
        else
          if task.nextPos?
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
      #console.log "current maxX:", params.maxX
      plTask.x = params.maxX + 1
      plTask.y = 0
      # запускаем ее обработку
      setWidth(tasks, plTask, params, roles)
      #console.log "tasks after setWidth:", tasks
      #resetPassed2(tasks)
      console.log "Нашли задачу без родителя: #{plTask.name}"
      assignCoordinates(tasks, plTask, params, rows, rolesOffsets)
      #console.log "params.matrix:", params.matrix

    #console.log "tasks after setWidth:", tasks
    #console.log "params.matrix:", params.matrix

    rows = makeTableFromCoordinates(tasks,params,rolesOffsets, roles)

    #console.log "rows before end:", rows

    rows.push [{task: _.findWhere(tasks, {type: "end"})}]
    params.maxY++

    #console.log "final rows:", rows

    # поля с данными
    entity = Entities.findOne({name: flow.entityName})
    #console.log "flow.entityName:", flow.entityName
    if entity?
      dataFields = entity.fields

    #console.log "dataFields:", dataFields
    data = {}
    data.dataFields = dataFields
    data.roles = returnedRoles
    data.params = params
    data.startTask = startTask
    data.rows = rows
    data.tasks = tasks
    data.flow = flow
    console.log "final data:", data
    return data
)
resetPassed = (tasks) ->
  for task in tasks
    task.passed = false

resetPassed2 = (tasks) ->
  for task in tasks
    task.passed2 = false

setWidth = (tasks, task, params, roles) ->
  if not task?
    return
  if task.type == "end"
    return
  if not task.roleWidth?
    task.roleWidth = {}
  for role in roles
    if not task.roleWidth[role]?
      task.roleWidth[role] = 0
  # пропускаем уже пройденные задачи
  if task.passed
    return
  else
    task.passed = true
  # есть разветвления?
  if task.decisions?
    for decision in task.decisions
      for nextPos in decision.nextPos
        decisionTask = _.findWhere(tasks, {pos: nextPos})
        if decisionTask.passed
          continue
        if decisionTask.type == "end"
          #addRoleWidth task, 1, task.roleId
          continue
        else
          setWidth(tasks, decisionTask, params, roles)
          #for role of decisionTask.roleWidth
            #;#addRoleWidth task, decisionTask.roleWidth[role], role
          addRoleWidth task, decisionTask.roleWidth[task.roleId], task.roleId
  else
    # находим следующую задачу
    for nextPos in task.nextPos
      nextTask = _.findWhere(tasks, {pos: nextPos})
      setWidth(tasks, nextTask, params, roles)
      if nextTask.type == "end"
        #addRoleWidth task, 1, task.roleId
      else if nextTask.roleWidth?
        for role of nextTask.roleWidth
          addRoleWidth task, nextTask.roleWidth[role], role
          #console.log "setWidth, role: #{role}, width: #{task.roleWidth[role]}"
      else
        #console.log "== strange, nextTask:", nextTask
      #console.log "roleWidth:", task.roleWidth
  task.roleWidth[task.roleId] = Math.max(task.roleWidth[task.roleId], 1)

addRoleWidth = (task, taskWidth, role) ->
  if not task.roleWidth?
    task.roleWidth = {}
  if not task.roleWidth[role]?
    task.roleWidth[role] = 0
  # если след. задача в другой роли - не прибавлять роль
  if task.roleId == role
    task.roleWidth[role] += taskWidth
  #console.log "addRoleWidth ended: #{task.name}.roleWidth[#{role}]:", task.roleWidth[role], ", taskWidth:#{taskWidth}"

# присвоить всем дочерним задачам координаты
assignCoordinates = (tasks, task, params, roleWidthMax, rolesOffsets) ->
  #console.log "Start assignCoordinates, task:", task
  # если уже присваивали координаты - прекратить
  if task.passed2 == true
    return
  task.passed2 = true
  console.log "assignCoordinates for #{task.name}"
  if task.type != "end"
    if task.type == "start"
      x = rolesOffsets[task.roleId]
      #console.log "startTask.x = ", x
    else
      x = task.x # + rolesOffsets[task.roleId]
    console.log "Setting matrix for task #{task.name}: task.x:#{task.x}, offset: #{rolesOffsets[task.roleId]}, coords: #{x}-#{task.y}: "#, task
    params.matrix["#{x}-#{task.y}"] = task
    params.maxX = Math.max(params.maxX, x)
    params.maxY = Math.max(params.maxY, task.y)
  else
    return
  # есть решения?
  if task.decisions?
    shift = {}
    # добавить блок предварительных данных
    if not task.preData?
      task.preData = {}
    # добавить в него данные по решению
    task.preData.decisions = task.decisions
    for decision in task.decisions
      # находим следующую задачу
      for nextPos in decision.nextPos
        decisionTask = _.findWhere(tasks, {pos: nextPos})
        if decisionTask.roleId?
          if not shift[decisionTask.roleId]?
            shift[decisionTask.roleId] = 0
        if decisionTask.passed2
          params.maxX = Math.max(params.maxX, task.x)
          #console.log "1 maxX:#{params.maxX}, task.x:#{task.x}"
          params.maxY = Math.max(params.maxY, task.y)
          continue
        else
          # присвоить задаче координаты
          console.log "task.x (#{task.x}) - rolesOffsets[task.roleId](#{rolesOffsets[task.roleId]}) + rolesOffsets[decisionTask.roleId](#{rolesOffsets[decisionTask.roleId]}) + shift[decisionTask.roleId](#{shift[decisionTask.roleId]}), decisionTask.roleId: #{decisionTask.roleId}"
          if decisionTask.roleId?
            decisionTask.x = task.x - rolesOffsets[task.roleId] + rolesOffsets[decisionTask.roleId] + shift[decisionTask.roleId]
          else
            decisionTask.x = task.x - rolesOffsets[task.roleId]
          decisionTask.y = task.y + 1
          shift[decisionTask.roleId]++
          params.maxX = Math.max(params.maxX, decisionTask.x)
          #console.log "2 maxX:#{params.maxX}, decisionTask.x:#{decisionTask.x}"
          params.maxY = Math.max(params.maxY, decisionTask.y)

          console.log "decisiontask.name:#{decisionTask.name}, x:#{decisionTask.x}, y:#{decisionTask.y}, shift:#{shift}, maxX:#{params.maxX}, maxY:#{params.maxY}"

          assignCoordinates(tasks, decisionTask, params, roleWidthMax, rolesOffsets)

    return
  else
    #console.log "Присваиваем координаты след. задачам #{task.name}"
    shift = {}
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
        #console.log "task.x:#{task.x}, task.roleId:#{task.roleId}, task:", task
        if task.type == "start"
          x = task.x
        else
          x = task.x - rolesOffsets[task.roleId]
        if not shift[nextTask.roleId]?
          shift[nextTask.roleId] = 0
        # вычислить координаты
        #console.log "x (#{x}) + rolesOffsets[#{nextTask.roleId}](#{rolesOffsets[nextTask.roleId]}) + shift[nextTask.roleId](#{shift[nextTask.roleId]}), nextTask.roleId: #{nextTask.roleId}"
        if nextTask.roleId?
          nextTask.x = x + rolesOffsets[nextTask.roleId] + shift[nextTask.roleId]
        else
          nextTask.x = x
        nextTask.y = task.y + 1
        shift[nextTask.roleId]++
        params.maxX = Math.max(params.maxX, nextTask.x)
        params.maxY = Math.max(params.maxY, nextTask.y)
        #console.log "3 maxX:#{params.maxX}, task.x:#{task.x}"

        #setRoleParam params.maxXRole, Math.max(params.maxX, nextTask.x), nextTask.roleId
        #setRoleParam params.maxYRole, Math.max(params.maxY, nextTask.y), nextTask.roleId

        #console.log "task.name:#{nextTask.name}, x:#{nextTask.x}, y:#{nextTask.y}, shift:#{shift}, maxX:#{params.maxX}, maxY:#{params.maxY}"

        # рекурсивно проставить всем задачам координаты
        assignCoordinates(tasks, nextTask, params, roleWidthMax, rolesOffsets)

makeTableFromCoordinates = (tasks, params, rolesOffsets, roles) ->
  #console.log "starting makeTableFromCoordinates, matrix:", params.matrix
  rowsInt = []
  #console.log "params.maxX:",params.maxX
  #console.log "params.maxY:",params.maxY
  #console.log "starting rowsInt in makeTableFromCoordinates:", rowsInt
  for j in [0..params.maxY]
    currentRow = []
    for i in [0..params.maxX]
      cell = {}
      for role in roles
        if rolesOffsets[role] == i
          cell.hasLeftBorder = true
      if i == params.maxX
        cell.hasRightBorder = true
      #taskInt = $.extend(true, {}, params.matrix["#{i}-#{j}"])
      taskInt = params.matrix["#{i}-#{j}"]
      #console.log "taskInt #{i}-#{j} in makeTableFromCoordinates:", taskInt
      if taskInt?
        cell.task = taskInt
      currentRow.push cell
      #console.log "currentRow: #{currentRow[0].task.type}", currentRow
    rowsInt.push currentRow
    #console.log "rowsInt in makeTableFromCoordinates:", rowsInt
  #console.log "final rows in makeTableFromCoordinates:", rowsInt
  return rowsInt
