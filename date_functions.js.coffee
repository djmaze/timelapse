DateHelper =
  padTwo: (number) ->
    result = if number < 10 then '0' else ''
    result + number

  date_as_time: (date) ->
    if date
      d = new Date date
      "#{this.padTwo d.getHours()}:#{this.padTwo d.getMinutes()}"

  today: ->
    now = new Date()
    new Date now.getYear()+1900, now.getMonth(), now.getDate()

  today_minus: (days) ->
    new Date( DateHelper.today() - (days*1000*60*60*24) )

  day_start: (date) ->
    new Date date.getYear(), date.getMonth(), date.getDate()
  day_end: (date) ->
    new Date date.getYear(), date.getMonth(), date.getDate(), 23, 59, 59

  duration: (seconds) ->
    hours = DateHelper.duration_hours(seconds)
    minutes = DateHelper.duration_minutes(seconds)
    "#{hours}h#{minutes}m"

  duration_hours: (seconds) ->
    Math.floor seconds / (60*60)
  duration_minutes: (seconds) ->
    DateHelper.padTwo Math.round (seconds % (60*60)) / 60

(exports ? this).DateHelper = DateHelper