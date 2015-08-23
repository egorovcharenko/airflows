myJobs.allow admin: (userId, method, params) ->
  #if userId? then true else false
  true

@setScheduleOnWeekday = (schedule, weekday, hour, minutes) ->
	schedule = schedule.and().on(weekday).dayOfWeek()
		.on(parseInt(hour)).hour()
		.on(parseInt(minutes)).minute()

@scheduleFromJson = (scheduleJson) ->
  #console.log "scheduleJson:", scheduleJson
  myJobs.later.date.localTime()
  schedule = myJobs.later.parse.recur()
  if scheduleJson.mon
    schedule = setScheduleOnWeekday schedule, 2, scheduleJson.hour, scheduleJson.minutes
  if scheduleJson.tue
    schedule = setScheduleOnWeekday schedule, 3, scheduleJson.hour, scheduleJson.minutes
  if scheduleJson.wed
    schedule = setScheduleOnWeekday schedule, 4, scheduleJson.hour, scheduleJson.minutes
  if scheduleJson.thu
    schedule = setScheduleOnWeekday schedule, 5, scheduleJson.hour, scheduleJson.minutes
  if scheduleJson.fri
    schedule = setScheduleOnWeekday schedule, 6, scheduleJson.hour, scheduleJson.minutes
  if scheduleJson.sat
    schedule = setScheduleOnWeekday schedule, 7, scheduleJson.hour, scheduleJson.minutes
  if scheduleJson.sun
    schedule = setScheduleOnWeekday schedule, 1, scheduleJson.hour, scheduleJson.minutes
  return schedule

processScheduleJobsWorker = (job, cb) ->
  switch job.type
    when "runScheduledFlows"
      job.log "data:", job.data.data
      flow = Flows.findOne({_id: job.data.flowId})
      Meteor.call 'runFlow', flow, (error, result) ->
        if not error?
          job.log "успешно запущен процесс, результат: #{result}"
          job.done()
        else
          job.log "процесс не запущен: #{error}"
          job.fail()
      return cb()

@runSchedulingForFlowId = (flowId) ->
  # найти работу для этого процесса
  job = myJobs.findOne({type: 'runScheduledFlows', 'data.flowId': flowId})
  #console.log "job:", job
  # удалить ее
  if job?
    job.cancel()
  # добавить новую
  addJobForFlow Flows.findOne({_id: flowId})

@reRunAllJobs = ->
  # перейти на локальное время на всякий случай
  myJobs.later.date.localTime();
  # Все задачи - отменить
  myJobs.find({type: 'runScheduledFlows', status: {$in: myJobs.jobStatusCancellable}})
    .forEach (j) ->
      j.cancel()
  # запустить все процессы, у которых есть расписание
  scheduledFlows = Flows.find({schedule: {$exists: true}}).fetch()
  for flow in scheduledFlows
    if flow.schedule?
      if flow.schedule.enabled
        addJobForFlow flow

@addJobForFlow = (flow) ->
  # пропускать удаленные процессы
  if flow.deleted == true
    return
  schedule = scheduleFromJson flow.schedule
  console.log("schedule for flow #{flow.prettyName}:", myJobs.later.schedule(schedule).next(5))
  # запустить процесс
  job = new Job myJobs, 'runScheduledFlows', {flowId: flow._id}
  job.priority('normal')
    .retry({retries: myJobs.forever, wait: 15*1000})
    .repeat({schedule: schedule})
    .after(new Date())
    .save({cancelRepeats: false})

Meteor.startup ->
  myJobs.startJobServer()

  myJobs.later.date.localTime();

  reRunAllJobs()

  # Начать обрабатывать задачи
  myJobs.processJobs ['runScheduledFlows'], { concurrency: 1, prefetch: 0, pollInterval: 5*1000 }, processScheduleJobsWorker

  # cleanups and remove stale jobs
  new Job(myJobs, 'cleanup', {})
    .repeat({ schedule: myJobs.later.parse.text("every 1 minute") })
    .save({cancelRepeats: true})

  new Job(myJobs, 'autofail', {})
    .repeat({ schedule: myJobs.later.parse.text("every 1 minute") })
    .save({cancelRepeats: true})

  q = myJobs.processJobs ['cleanup', 'autofail'], { pollInterval: 100000000 }, (job, cb) ->
    current = new Date()
    switch job.type
      when 'cleanup'
        current.setMinutes(current.getMinutes() - 60)
        ids = myJobs.find({
          status:
            $in: Job.jobStatusRemovable
          updated:
            $lt: current},
          {fields: { _id: 1 }}).map (d) -> d._id
        myJobs.removeJobs(ids) if ids.length > 0
        # console.warn "Removed #{ids.length} old jobs"
        job.done("Removed #{ids.length} old jobs")
        cb()
      when 'autofail'
        c = 0
        current.setMinutes(current.getMinutes() - 10)
        myJobs.find({
          status: 'running'
          updated:
            $lt: current})
          .forEach (j) ->
            c++
            #console.log j
            j.fail "Timed out by autofail"
        # console.warn "Failed #{c} stale running jobs"
        job.done "Failed #{c} stale running jobs"
        cb()
      else
        job.fail "Bad job type in worker"
        cb()

  myJobs.find({ type: { $in: ['cleanup', 'autofail']}, status: 'ready' })
    .observe
      added: () -> q.trigger()
