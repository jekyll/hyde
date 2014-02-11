# Description:
#   Get the CI status reported to GitHub for a repo and pull request
#
# Dependencies:
#   "githubot": "0.4.x"
#
# Configuration:
#   HUBOT_GITHUB_TOKEN
#   HUBOT_GITHUB_USER
#   HUBOT_GITHUB_API
#
# Commands:
#   hubot status jekyll/jekyll 2004
#   hubot status 2004
#
# Notes:
#   HUBOT_GITHUB_API allows you to set a custom URL path (for Github enterprise users)
#
# Author:
#   mattr-

module.exports = (robot) ->
  github = require("githubot")(robot)
  robot.respond /status (\w+\/\w+)?\s*#?(\d+)/i, (msg) ->
    repo = github.qualified_repo msg.match[1]
    pr_number = msg.match[2]
    base_url = process.env.HUBOT_GITHUB_API || 'https://api.github.com'
    pull_url = "#{base_url}/repos/#{repo}/pulls/#{pr_number}"

    github.handleErrors (response) ->
      msg.send "#{response.error}"

    github.get pull_url, (pull) ->
      github.get pull.statuses_url, (status) ->
        last_status = status[0]
        msg.send "#{last_status.state} - #{last_status.target_url}"
