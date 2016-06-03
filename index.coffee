# Description:
#
#   Skeddly integration for listing, starting and stopping actions.
#
# Commands:
#
#   hubot list actions - list all the Skeddly actions
#   hubot list upcoming actions - lists all upcoming actions
#   hubot list running actions - list all running actions
#   hubot list failed actions - list failed exections in the last 30 days
#   hubot start action <action name> - starts an action
#   hubot stop action <action name> - stops all running executions of an action
#
# Dependencies:
#
#   "moment": "2.13.0"
#
# Configuration:
#
#   HUBOT_SKEDDLY_API_KEY - API key for the Skeddly API
#
# Notes:
#
# Authors:
#
#   Matt Houser
#

moment = require('moment')

skeddlyBaseUrl = "https://api.skeddly.com/api"
skeddlyApiKey = process.env.HUBOT_SKEDDLY_API_KEY

class SkeddlyError extends Error

module.exports = (robot) ->

  robot.hear /skeddly/i, (res) ->
    res.send "Skeddly rocks!!"

  robot.respond /list actions/i, (res) ->
    skeddlyListActions robot, (err, actions) ->
      if err?
        robot.emit 'error', err, res
        return

      output = "The current list of Skeddly actions are:\n"
      for action in actions
        output += "     #{action.name} (#{action.actionId})\n"
      res.send output
	
  robot.respond /start action (.*)/i, (res) ->
    actionName = res.match[1]

    skeddlyListActions robot, (err, actions) ->
      if err?
        robot.emit 'error', err, res
        return

      actionsToStart = []
      for action in actions
        if action.name.toUpperCase() is actionName.toUpperCase()
          actionsToStart.push action

      if actionsToStart.length is 0
        res.send "Action '#{actionName}' was not found"
        return

      res.send "Starting #{actionsToStart.length} action(s)"

      for action in actionsToStart
        localActionName = action.name
        localActionId = action.actionId
        skeddlyStartAction robot, action.actionId, (err, actionExecution) ->
          if err?
            robot.emit 'error', err, res
            return

          res.send "  Action '#{localActionName}' (#{localActionId}) started.\n"
          res.send "     Link: https://app.skeddly.com/Activity/Log/#{actionExecution.actionExecutionId}\n"

  robot.respond /list running actions/i, (res) ->
    skeddlyListRunningActions robot, (err, actionExecutions) ->
      if err?
        robot.emit 'error', err, res
        return

      if actionExecutions.length is 0
        res.send "There are no running actions."
        return

      output = "These are the running Skeddly actions:\n"
      for actionExecution in actionExecutions
        startDate = moment(actionExecution.startDate).calendar()
        output += "  Action '#{actionExecution.actionName}' is running. It started #{startDate}.\n"
        output += "     Link: https://app.skeddly.com/Activity/Log/#{actionExecution.actionExecutionId}\n"
      res.send output

  robot.respond /list upcoming actions/i, (res) ->
    skeddlyListUpcomingActions robot, (err, actions) ->
      if err?
        robot.emit 'error', err, res
        return

      if actions.length is 0
        res.send "There are no upcoming actions."
        return

      output = "These are the upcoming Skeddly actions:\n"
      for action in actions
        startDate = moment(action.startDate).calendar()
        output += "  '#{action.actionName}' will start #{startDate}.\n"
      res.send output

  robot.respond /list failed actions/i, (res) ->
     skeddlyListFailedExecutions robot, (err, actionExecutions) ->
      if err?
        robot.emit 'error', err, res
        return

      if actionExecutions.length is 0
        res.send "There are no failed actions. Everything is happy!"
        return

      output = "These are the Skeddly actions that failed:\n"
      for actionExecution in actionExecutions
        startDate = moment(actionExecution.startDate).calendar()
        output += "  '#{actionExecution.actionName}' started #{startDate}.\n"
      res.send output

  robot.respond /stop action (.*)/i, (res) ->
    actionName = res.match[1]
    skeddlyListRunningActions robot, (err, actionExecutions) ->
      if err?
        robot.emit 'error', err, res
        return

      actionsToStop = []
      for actionExecution in actionExecutions
        if actionExecution.actionName.toUpperCase() is actionName.toUpperCase()
          actionsToStop.push actionExecution

      if actionsToStop.length is 0
        res.send "There are no actions called '#{actionName}' that are running."
        return

      for actionExection in actionsToStop
          localActionExecutionId = actionExecution.actionExecutionId
          skeddlyStopActionExecution robot, actionExecution.actionExecutionId, (err) ->
            if err?
              robot.emit 'error', err, res
              return

            res.send "Action execution #{localActionExecutionId} was stopped."

  skeddlyListActions = (robot, cb) ->
    skeddlyGet robot, "/Actions", null, (err, json) ->
      cb(err, json)

  skeddlyStartAction = (robot, actionId, cb) ->
    skeddlyPut robot, "/Actions/" + actionId + "/Execute", null, (err, json) ->
      cb(err, json)

  skeddlyStopActionExecution = (robot, actionExecutionId, cb) ->
    skeddlyPut robot, "/ActionExecutions/" + actionExecutionId + "/Cancel", null, (err, json) ->
      cb(err, json)

  skeddlyListUpcomingActions = (robot, cb) ->
    skeddlyGet robot, "/ActionExecutions/Upcoming", null, (err, json) ->
      cb(err, json)

  skeddlyListRunningActions = (robot, cb) ->
    query = {};
    query["filter.status"] = "runningOnly"
    skeddlyGet robot, "/ActionExecutions", query, (err, json) ->
      cb(err, json)

  skeddlyListFailedExecutions = (robot, cb) ->
    query = {};
    query["filter.status"] = "errorsOnly"
    skeddlyGet robot, "/ActionExecutions", query, (err, json) ->
      cb(err, json)

  skeddlyGet = (robot, url, query, cb) ->
    if missingEnvironmentForApi(robot)
      return

    unless query?
      query = {}

    auth = "AccessKey #{skeddlyApiKey}"
    robot.http(skeddlyBaseUrl + url)
      .query(query)
      .headers(Authorization: auth, Accept: 'application/json')
      .get() (err, res, body) ->
        if err?
          return cb(err)

        json_body = null
        switch res.statusCode
          when 200 then json_body = JSON.parse(body)
          when 204 then json_body = null
          else
            return cb(new SkeddlyError("#{res.statusCode} back from #{url}")) 
        cb null, json_body

  skeddlyPut = (robot, url, data, cb) ->
    if missingEnvironmentForApi(robot)
      return

    unless query?
      query = {}
    json = JSON.stringify(data)

    auth = "AccessKey #{skeddlyApiKey}"
    robot.http(skeddlyBaseUrl + url)
      .headers(Authorization: auth, Accept: 'application/json')
      .header("content-type","application/json")
      .header("content-length",json.length)
      .put(json) (err, res, body) ->
        if err?
          return cb(err)

        json_body = null
        switch res.statusCode
          when 200 then json_body = JSON.parse(body)
          when 204 then json_body = null
          else
            return cb(new SkeddlyError("#{res.statusCode} back from #{url}"))
        cb null, json_body

  missingEnvironmentForApi = (robot) ->
    missingAnything = false
    unless skeddlyApiKey?
      robot.send "Skeddly API Key is missing:  Ensure that HUBOT_SKEDDLY_API_KEY is set."
      missingAnything |= true
    missingAnything
