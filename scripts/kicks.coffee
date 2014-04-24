# Description:
#   Hubot responds to your cruelty. At least it's only a robot.

gifs =
  come_at_me_bro: "http://themisadventuresof.com/wp-content/uploads/2013/09/comebro.gif"

module.exports = (robot) ->
  robot.hear /kicks hubot/i, (msg) ->
    msg.send "*oof*"
  
  robot.hear /(hubot you suck|you suck hubot)/i, (msg) ->
    msg.send gifs.come_at_me_bro

