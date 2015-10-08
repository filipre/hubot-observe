# Description
#   A hubot script that checks a json resource and notifies the channel if something changed
#
# Configuration:
#   LIST_OF_ENV_VARS_TO_SET
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
# humanToCron = require('human-to-cron')

jobs = {}

# model
# robot.brain.data.observe.<room>.<url> = <interval>

createJob = (url, interval, room, robot) ->
  return new CronJob(
    cronTime: interval # humanToCron interval
    onTick: ->
      robot.messageRoom room, "I have a secret: #{url}, #{interval}, #{room}"
    start: true
  )

provideCommands = (robot) ->

  robot.respond /observe(:help)?$/i, (msg) ->

    msg.reply "List of commands:"
    # TODO


  robot.respond /observe:add ([^\s\\]+)( interval=([^\"]+))?/i, (msg) ->

    url = msg.match[1]
    interval = msg.match[3] || "0 * * * * *" #default: minutely
    room = msg.message.room

    robot.brain.data.observe[room] ?= {}

    if robot.brain.data.observe[room].hasOwnProperty(url)
      msg.reply "URL already exists in ##{room}"
      return

    jobs[room] ?= {}
    jobs[room][url] = createJob url, interval, room, robot

    # source of truth
    robot.brain.data.observe[room][url] = interval

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

    all = if msg.match[1] then true else false
    room = msg.message.room

    if all
      reply = "All jobs from all rooms:"
      for roomName, roomObj of robot.brain.data.observe
        for url, interval of roomObj
          reply += "\n##{roomName}: #{url} [#{interval}]"
      msg.reply reply
      return

    reply = "All jobs from ##{room}:"
    robot.brain.data.observe[room] ?= {}
    for url, interval of robot.brain.data.observe[room]
      reply += "\n##{room}: #{url} [#{interval}]"
    msg.reply reply


module.exports = (robot) ->

  robot.brain.on 'loaded', =>
    robot.brain.data.observe ?= {}

    # load existing jobs from the brain
    for roomName, roomObj of robot.brain.data.observe
      for url, interval of roomObj
        jobs[roomName] ?= {}
        jobs[roomName][url] = createJob url, interval, roomName, robot

    # only provide methods if brain is loaded
    provideCommands robot
