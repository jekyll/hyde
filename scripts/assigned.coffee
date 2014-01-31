# Description:
#   Get a list of the issues assigned to your on a repo
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
#   hubot assigned to me
#   hubot assigned to mattr-
#   hubot assigned to me 4
#   hubot assigned to me jekyll/hyde
#   hubot assigned to me jekyll/hyde 4
#
# Notes:
#   HUBOT_GITHUB_API allows you to set a custom URL path (for Github enterprise users)
#
# Author:
#   parkr

_ = require('underscore')

api_url = ->
  process.env.HUBOT_GITHUB_API || "https://api.github.com"

issues_url = (repo) ->
  "#{api_url}/repos/#{repo}/issues"

limit_issues = (issues, limit) ->
  issues = _.first issues, limit

module.exports = (robot) ->
  github = require("githubot")(robot)
  robot.respond /assigned to (me|[\w\-_]+) ?(\w+\/[\w\-_]+)? ?(\d+)?/i, (msg) ->
    assignee = msg.match[1]
    repo = github.qualified_repo msg.match[2]
    limit = msg.match[3] if msg.match[3]?

    query_params =
      state: "open",
      sort: "created",
      assignee: assignee

    github.get issues_url(repo), (all_issues) ->
      issues = limit_issues(issues, limit) if limit?
      if _.isEmpty issues
        msg.send "No open issues found for #{assignee}. Yay!"
      else
        for issue in issues
          msg.send "##{issue.number} #{issue.title} #{issue.html_url}"
