# Description
#   A hubot script that checks a json resource and notifies the channel if something changed
#
# Commands:
#   hubot observe[:help] - Show commands
#   hubot observe:add <url> [interval=<interval>] - Add a job that observes a json with an optional interval (default is minutely)
#   hubot observe:remove <url> - Remove a job by url
#   hubot observe:list [all] - List all jobs in the room (or of all rooms)
#
# Notes:
#   Hubot's Brain is required for this script
#
# Author:
#   René Filip <renefilip@mail.com>


CronJob = require('cron').CronJob
async = require 'async'
# humanToCron = require('human-to-cron')

# Running "Cronjobs" by the npm cron package
jobs = {}


checkUrl = (url, room, robot) ->

  performRequest = (callback, result) ->
    robot.http(url).get() (err, res, body) ->
      # HTTP error
      if err
        return callback err, null

      # JSON Parsing Error (maybe not a json)
      try
        result = JSON.parse body
      catch err
        return callback err, null

      # no 'text' property
      if not result.hasOwnProperty 'text'
        err = "JSON does not have a 'text' property at root"
        return callback err, null

      return callback null, result.text

  notifyUser = (err, text) ->
    # after 3 tries mark url as broken and notify user the first time
    if err
      if not robot.brain.data.observe[room][url].broken
        robot.messageRoom room, "#{url} is not working: #{err}"
      robot.brain.data.observe[room][url].broken = true
      return

    # URL is working (again)
    robot.brain.data.observe[room][url].broken = false
    if robot.brain.data.observe[room][url].text isnt text
      robot.brain.data.observe[room][url].text = text
      robot.messageRoom room, "#{text}"

  async.retry {
    times: 3
    interval: 5000
  }, performRequest, notifyUser


createJob = (url, room, robot) ->
  return new CronJob(
    cronTime: robot.brain.data.observe[room][url].interval # humanToCron interval
    onTick: ->
      checkUrl url, room, robot
    start: true
  )


provideCommands = (robot) ->

  robot.respond /observe(:help)?$/i, (msg) ->

    help = "List of commands:"
    help += "\n#{robot.name} observe[:help] - Show commands"
    help += "\n#{robot.name} observe:add <url> [interval=<interval>] - Add a job that observes a json with an optional interval (default is minutely)"
    help += "\n#{robot.name} observe:remove <url> - Remove a job by url"
    help += "\n#{robot.name} observe:list [all] - List all jobs in the room (or of all rooms)"

    msg.reply help


  robot.respond /observe:add ([^\s\\]+)( interval=([^\"]+))?/i, (msg) ->

    url = msg.match[1]
    interval = msg.match[3] || "0 * * * * *" #default: minutely
    room = msg.message.room

    robot.brain.data.observe[room] ?= {}

    if robot.brain.data.observe[room].hasOwnProperty(url)
      msg.reply "URL already exists in ##{room}"
      return

    # source of truth
    robot.brain.data.observe[room][url] =
      interval: interval
      text: ""
      broken: false

    jobs[room] ?= {}
    jobs[room][url] = createJob url, room, robot

    msg.reply "#{url} in ##{room} added"


  robot.respond /observe:remove ([^\s\\]+)/i, (msg) ->

    url = msg.match[1]
    room = msg.message.room

    robot.brain.data.observe[room] ?= {}

    if !robot.brain.data.observe[room].hasOwnProperty(url)
      msg.reply "#{url} in ##{room} does not exist"
      return

    jobs[room][url].stop()
    delete jobs[room][url]
    delete robot.brain.data.observe[room][url]

    msg.reply "#{url} in ##{room} deleted"


  robot.respond /observe:list( all)?/i, (msg) ->

    formatJob = (room, url, interval, broken) ->
      brokenStr = if observeObj.broken then "(broken)" else ""
      return "\n##{room}: #{url} [#{interval}] #{brokenStr}"

    all = if msg.match[1] then true else false
    room = msg.message.room

    if all
      reply = "All jobs from all rooms:"
      for room, roomObj of robot.brain.data.observe
        for url, observeObj of roomObj
          reply += formatJob room, url, observeObj.interval, observeObj.broken
      msg.reply reply
      return

    reply = "All jobs from ##{room}:"
    robot.brain.data.observe[room] ?= {}
    for url, observeObj of robot.brain.data.observe[room]
      reply += formatJob room, url, observeObj.interval, observeObj.broken
    msg.reply reply


module.exports = (robot) ->

  robot.brain.on 'loaded', =>
    robot.brain.data.observe ?= {}

    # load existing jobs from the brain
    for roomName, roomObj of robot.brain.data.observe
      for url, observeObj of roomObj
        jobs[roomName] ?= {}
        jobs[roomName][url] = createJob url, roomName, robot

    # only provide methods if brain is loaded
    provideCommands robot
