# Description:
#   Allows users to post a tweet to Twitter using common shared
#   Twitter accounts.
#
#   Requires a Twitter consumer key and secret, which you can get by
#   creating an application here: https://dev.twitter.com/apps
#
#   Based on KevinTraver's twitter.coffee script: http://git.io/iCQPyA
#
#   HUBOT_TWEETER_ACCOUNTS should be a string that parses to a JSON
#   object that contains access_token and access_token_secret for each
#   twitter screen name you want to allow people to use.
#
#   For example:
#   {
#     "hubot" : { "access_token" : "", "access_token_secret" : ""},
#     "github" : { "access_token" : "", "access_token_secret" : ""}
#   }
#
# Commands:
#   hubot tweet@<screen_name> <update> - posts <update> to Twitter as <screen_name>
#   hubot untweet@<screen_name> <tweet_id> - deletes <tweet_id> from Twitter
#   hubot rt@<screen_name> <tweet_url_or_id> - <screen_name> retweets <tweet_url_or_id>
#
# Dependencies:
#   "twit": "1.1.8"
#   "twitter-text": "1.7.x"
#
# Configuration:
#   HUBOT_TWITTER_CONSUMER_KEY
#   HUBOT_TWITTER_CONSUMER_SECRET
#   HUBOT_TWEETER_ACCOUNTS
#
# Author:
#   jhubert
#
# Repository:
#   https://github.com/jhubert/hubot-tweeter

Twit = require "twit"
twitterText = require "twitter-text"
config =
  consumer_key: process.env.HUBOT_TWITTER_CONSUMER_KEY
  consumer_secret: process.env.HUBOT_TWITTER_CONSUMER_SECRET
  accounts_json: process.env.HUBOT_TWEETER_ACCOUNTS

authenticated_twit = (username) ->
  new Twit
    consumer_key: config.consumer_key
    consumer_secret: config.consumer_secret
    access_token: config.accounts[username].access_token
    access_token_secret: config.accounts[username].access_token_secret

unless config.consumer_key
  console.log "Please set the HUBOT_TWITTER_CONSUMER_KEY environment variable."
unless config.consumer_secret
  console.log "Please set the HUBOT_TWITTER_CONSUMER_SECRET environment variable."
unless config.accounts_json
  console.log "Please set the HUBOT_TWEETER_ACCOUNTS environment variable."

config.accounts = JSON.parse(config.accounts_json || "{}")

module.exports = (robot) ->
  robot.respond /tweet\@([^\s]+)$/i, (msg) ->
    msg.reply "You can't very well tweet an empty status, can ya?"
    return

  robot.respond /tweet\@([^\s]+)\s(.+)$/i, (msg) ->

    username = msg.match[1].toLowerCase()
    update   = msg.match[2].trim()

    unless config.accounts[username]
      msg.reply "I'm not setup to send tweets on behalf of #{msg.match[1]}. Sorry."
      return

    unless update and update.length > 0
      msg.reply "You can't very well tweet an empty status, can ya?"
      return

    tweetOverflow = twitterText.getTweetLength(update) - 140
    if tweetOverflow > 0
      msg.reply "Your tweet is #{tweetOverflow} characters too long. Twitter users can't read that many characters!"
      return

    authenticated_twit(username).post "statuses/update",
      status: update
    , (err, reply) ->
      if err
        msg.reply "I can't do that. #{err.message} (error #{err.statusCode})"
        return
      if reply['text']
        msg.send "#{reply['user']['screen_name']} just tweeted: '#{reply['text']}'."
        return msg.send "To delete, run 'hubot untweet@#{username} #{reply['id_str']}'."
      else
        return msg.reply "Hmmm. I'm not sure if the tweet posted. Check the account: http://twitter.com/#{username}"

  robot.respond /untweet\@([^\s]+)\s(.*)/i, (msg) ->
    username = msg.match[1]
    tweet_id = msg.match[2]

    authenticated_twit(username).post "statuses/destroy/#{tweet_id}", {}, (err, reply) ->
      if err
        msg.reply "I can't do that. #{err.message} (error #{err.statusCode})"
        return
      if reply['text']
        return msg.send "#{reply['user']['screen_name']} just deleted tweet: '#{reply['text']}'."
      else
        return msg.reply "Hmmm. I'm not sure if the tweet was deleted. Check the account: http://twitter.com/#{username}"

  robot.respond /rt\@([^\s]+)\s(.*)/i, (msg) ->
    username = msg.match[1]
    tweet_url_or_id = msg.match[2]

    tweet_id_match = tweet_url_or_id.match(/(\d+)$/)
    unless tweet_id_match && tweet_id_match[0]
      msg.reply "Sorry, '#{tweet_url_or_id}' doesn't contain a valid id."
      return

    tweet_id = tweet_id_match[0]

    authenticated_twit(username).post "statuses/retweet/#{tweet_id}", (err, reply) ->
      if err
        msg.reply "I can't do that. #{err.message} (error #{err.statusCode})"
        return
      if reply['text']
        return msg.send "#{reply['user']['screen_name']} just tweeted: #{reply['text']}"
      else
        return msg.reply "Hmmm. I'm not sure if that retweet posted. Check the account: http://twitter.com/#{username}"
