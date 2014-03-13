# Description:
#   Get a list of the issues assigned to your on a repo
#
# Dependencies:
#   node-geocoder
#
#
# Configuration:
#   HUBOT_TIMEZONEDB_API_KEY
#
# Commands:
#   hubot where is <username>
#   hubot <username> is in <location>
#   hubot time me [username]
#
# Author:
#   parkr

geocoder = require('node-geocoder').getGeocoder('google', 'http', {})
timezonedbKey = process.env["HUBOT_TIMEZONEDB_API_KEY"]

unless timezonedbKey?
  console.log "Whoops, can't use /time me, as HUBOT_TIMEZONEDB_API_KEY isn't set."

monthNames = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December"
]

dayNames = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday"
]

now = ->
  Math.round(new Date().getTime() / 1000)

userId = (robot, userName) ->
  robot.brain.usersForFuzzyName(userName)[0].id

locationForUser = (robot, userName) ->
  robot.brain.data.locations[userId(robot, userName)]

setLatitudeAndLongitudeOnUser = (robot, user, lat, lon) ->
  id = userId(robot, user)
  robot.brain.data.locations[id]       ?= {}
  robot.brain.data.locations[id]["lat"] = lat
  robot.brain.data.locations[id]["lon"] = lon

setLocationForUser = (robot, user, location, cb) ->
  robot.brain.data.locations[userId(robot, user)] ?= {}
  robot.brain.data.locations[userId(robot, user)]["stringLocation"] = location
  geocodeNewLocation robot, user, location, cb

geocodeNewLocation = (robot, user, location, cb) ->
  geocoder.geocode location, (err, res) ->
    if err
      console.log err
      cb("There was an error: #{err}")
    else
      setLatitudeAndLongitudeOnUser(robot, user, res[0].latitude, res[0].longitude)
      cb("Ok, updated #{user}'s location to '#{location}'")

relativeToNoon = (hours) ->
  if hours - 12 > 0
    "PM"
  else
    "AM"

formattedUnixTime = (timestamp) ->
  date = new Date(parseInt(timestamp) * 1000)
  console.log date
  "#{dayNames[date.getUTCDay()]}, #{monthNames[date.getUTCMonth()]} #{date.getUTCDate()} at #{date.getUTCHours()}:#{date.getUTCMinutes()} #{relativeToNoon(date.getUTCHours())}."

timeAtLatitudeAndLongitude = (robot, location, cb) ->
  robot.http("http://api.timezonedb.com/").query
    key: timezonedbKey,
    lat: location.lat,
    lng: location.lon,
    time: now(),
    format: "json"
  .get() (err, res, body) ->
    if err or JSON.parse(body).status != "OK"
      cb "An error occurred fetching the time :("
    else
      info = JSON.parse body
      cb "It's currently #{formattedUnixTime info.timestamp} in #{location.stringLocation}."

module.exports = (robot) ->
  robot.brain.data.locations ?= {}

  robot.respond /time me ([\w\-]+)/i, (msg) ->
    user = msg.match[1]
    if user? and robot.brain.data.locations[userId(robot, user)]?
      location = robot.brain.data.locations[userId(robot, user)]
      timeAtLatitudeAndLongitude robot, location, (message) ->
        msg.send message
    else
      msg.send "Sorry, I don't know where #{user} is so I can't tell what time zone he or she is in. :("

  robot.respond /([\w\-]+) is in (.*)/i, (msg) ->
    user = msg.match[1]
    location = msg.match[2]
    setLocationForUser robot, user, location, (message) ->
      msg.send message

  robot.respond /where is ([\w\-]+)/i, (msg) ->
    user     = msg.match[1]
    location = locationForUser(robot, user)
    if location?
      msg.send "#{user} is in #{location.stringLocation}."
    else
      msg.send "Sorry, no idea where #{user} is."