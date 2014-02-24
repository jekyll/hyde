# Description:
#   Hubot responds to your cruelty. At least it's only a robot.

module.exports = (robot) ->
  robot.hear /kicks hubot/i, (msg) ->
    msg.send "*oof*"
