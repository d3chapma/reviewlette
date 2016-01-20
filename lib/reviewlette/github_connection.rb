require 'yaml'
require 'octokit'

class GithubConnection
  attr_accessor :client, :repo

  def initialize(repo, token)
    @client  = Octokit::Client.new(access_token: token)
    @repo    = repo
  end

  def list_pulls
    @client.pull_requests(@repo)
  end

  def add_assignee(number, assignee)
    @client.update_issue(@repo, number, assignee: assignee)
  end

  def comment_reviewers(number, reviewers, trello_card)
    assignees = reviewers.first['github_username']

    reviewers.drop(1).each do |reviewer|
      assignees += " and #{reviewer['github_username']}"
    end


    comment = "@#{assignees} reviews your pull request :dancers: check #{trello_card.url} \n" \
              "@#{assignees}: Please review this pull request using our guidelines: \n" \
              "* test for acceptance criteria / functionality \n" \
              "* check if the new code is covered with tests \n" \
              "* check for unintended consequences \n" \
              "* encourage usage of the boyscout rule \n" \
              "* make sure the code is architected in the best way \n" \
              "* check that no unnecessary technical debt got introduced \n" \
              "* make sure that no unnecessary FIXMEs or TODOs got added \n"
    @client.add_comment(@repo, number, comment)
  end

  def unassigned_pull_requests
    list_pulls.select { |issue| !issue[:assignee] }
  end

  def repo_exists?
    @client.repository?(@repo)
  end
end
