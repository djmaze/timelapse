Timers = new Meteor.Collection("timers")

if Meteor.is_client

  parentContext = (node) ->
    context = Meteor.ui._LiveRange.findRange Meteor.ui._tag, node
    return null unless (parent = do context.findParent)?
    return parent.event_data

  Template.date.events =
    'change select.date': (e) ->
      val = moment().startOf('day').add 'days', $(e.target).val()
      date = val.toDate().toISOString()
      Session.set 'date', date
      window.history.pushState(null, val, '/'+date)   # TODO

  # TODO
  Template.date.date_is = (val) ->
    val = moment().startOf('day').add 'days', val
    date = val.toDate().toISOString()
    Session.equals 'date', date


  Template.timers.timers = ->
    date = Session.get('date') || window.location.pathname[1..]
    date = if date then new Date(date) else new Date()
    t = Timers.find { date: $gte: moment(date).startOf('day').toDate().toISOString(), $lte: moment(date).endOf('day').toDate().toISOString() }, sort: { cleared: -1, date: 1 }
    console.log t
    t

  Template.timers.total_time = (timers) ->
    t = timers.fetch()
    if t.length > 1
      DateHelper.duration t.reduce (a, b) ->
        (if a.times then Template.timer.elapsed_seconds(a.times) else a) + Template.timer.elapsed_seconds(b.times)


  Template.timer.short_date = ->
    $.format.date @date, 'dd.MM.'

  Template.timer.running_class = ->
    if this.is_running
      #Template.timer.start_timer(this)    # HACK because of missing startup hook
      'running'
    else if this.cleared then 'cleared'
    else ''

  Template.meta_title.running_timer = ->
    title = Session.get('timer_title')
    if title then title += ' ' else title = ''
    $('title').text title + '[timelapse]'
    ''

  Template.timer.elapsed = ->
    DateHelper.duration Template.timer.current_duration(this)
  Template.timer.elapsed_hours = ->
    DateHelper.duration_hours Template.timer.current_duration(this)
  Template.timer.elapsed_minutes = ->
    DateHelper.duration_minutes Template.timer.current_duration(this)
  Template.timer.current_duration = (timer) ->
    if timer.is_running
      Session.get('current_duration')
    else
      Template.timer.elapsed_seconds(timer.times)

  Template.timer.elapsed_seconds = (times) ->
    duration = (time) ->
      if time.started_at
        if time.stopped_at
          (new Date(time.stopped_at) - new Date(time.started_at)) / 1000
        else
          0
      else
        time

    if !times
      0
    else if times.length == 1 and times[0].stopped_at
      (new Date(times[0].stopped_at) - new Date(times[0].started_at)) / 1000
    else if times.length > 1
      times.reduce (a, b) ->
        duration(a) + duration(b)
    else
      0

  Template.timer.start_stop = ->
    if this.is_running then 'Stop' else 'Start'

  Template.timer.cleared_checked = ->
    if this.cleared then 'checked' else ''

  # TODO
  Template.timer.start_timer = (timer) ->
    if timer and !Template.timer.current_timer
      console.log "Starting timer '#{timer.description}'"
      Session.set 'timer_title', timer.description
      Session.set 'current_duration', Template.timer.elapsed_seconds timer.times

      interval_seconds = 10
      Template.timer.current_timer = Meteor.setInterval ->
        current_duration = Session.get('current_duration') + interval_seconds
        console.log "Timer '#{timer.description}' running, #{current_duration} seconds"
        Session.set 'current_duration', current_duration
      , interval_seconds * 1000

  Template.timer.stop_timer = ->
    console.log "Timer stopping"
    if Template.timer.current_timer
      Meteor.clearInterval Template.timer.current_timer
      delete Template.timer.current_timer
    Session.set 'timer_title', null
    Session.set 'current_duration', null


  Template.timer.time =
    started_at: ->
      DateHelper.date_as_time @started_at
    stopped_at: ->
      DateHelper.date_as_time @stopped_at
    comment: ->
      @comment
    duration: ->
      if @stopped_at
        DateHelper.duration (new Date(@stopped_at) - new Date(@started_at)) / 1000

  Template.timers.events =

    'submit #new-timer form' : (e) ->
      # template data, if any, is available in 'this'
      Timers.insert
        date: (new Date()).toISOString()
        description: $(e.target).children('.description').val()
      $(e.explicitOriginalTarget).val('')
      false

    'click input.toggle_times': (e) ->
      $('.timer .time').toggle()

    'click input.start-stop': (e) ->
      button = $(e.target)
      #timer_div = button.parent('.timer')

      if this.is_running
        # stop
        Template.timer.stop_timer()

        t = Timers.findOne this._id
        Timers.update this._id, $set: is_running: false # TODO close entry

        # Update last time
        last_time = this.times[-1..][0]
        last_time.stopped_at = (new Date()).toISOString()
        Timers.update this._id, $pop: times: 1
        Timers.update this._id, $push: times: last_time
      else
        # start
        Template.timer.start_timer this

        Timers.update this._id,
          $set: is_running: true
        Timers.update this._id,
          $push: times: started_at: (new Date()).toISOString()

    'change input.description': (e) ->
      if this._id
        Timers.update this._id, $set: description: $(e.target).val()

    'change input.cleared': (e) ->
      is_checked = if $(e.target).is(':checked') then true else false
      Timers.update this._id, $set: cleared: is_checked

    'click input.delete': ->
      if confirm("\"#{this.description}\" löschen?")
        Timers.remove this._id

    'change .time textarea.comment': (e) ->
      val = $(e.target).val()
      timer = parentContext(e.target)

      timer.times[i].comment = val for time, i in timer.times when time.started_at == this.started_at
      Timers.update timer._id, $set: times: timer.times

    'click .time input.delete_time': (e) ->
      timer = parentContext(e.target)
      Timers.update timer._id, $pull: times: started_at: (new Date(this.started_at)).toISOString()


if Meteor.is_server
  Meteor.startup ->
    # code to run on server at startup
    Session.set('date', DateHelper.today().toISOString())
