require 'octokit'

class Reviewlette
  class GithubConnection
    attr_accessor :client, :repo

    def initialize(repo, token)
      @client  = Octokit::Client.new(access_token: token)
      @repo    = repo
    end

    def pull_requests
      @client.pull_requests(@repo)
    end

    def trello_card(issue)
      comments = @client.issue_comments(@repo, issue.number)
      comment = comments.detect do |c|
        c[:body].match(/trello\.com/)
      end

      _, trello_card = comment[:body].match(/https:\/\/trello.com\/c\/\w+\/(\d+)-/).to_a
      trello_card.to_i
    end

    def labels(issue)
      @client.labels_for_issue(@repo, issue).map(&:name)
    end

    def add_assignees(number, assignees)
      @client.update_issue(@repo, number, assignees: assignees)
    end

    def comment_reviewers(number, reviewers, trello_card)
      assignees = reviewers.map { |r| "@#{r.github_handle}" }.join(' and ')

      comment = <<-eos
  #{assignees} will review your pull request :dancers: check #{trello_card.url}
  #{assignees}: Please review this pull request using our guidelines:
  * test for acceptance criteria / functionality
  * check if the new code is covered with tests
  * check for unintended consequences
  * encourage usage of the boyscout rule
  * make sure the code is architected in the best way
  * check that no unnecessary technical debt got introduced
  * make sure that no unnecessary FIXMEs or TODOs got added
      eos

      @client.add_comment(@repo, number, comment)
    end

    def repo_exists?
      @client.repository?(@repo)
    end
  end
end
