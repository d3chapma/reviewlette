require 'reviewlette/trello_connection'
require 'reviewlette/github_connection'
require 'reviewlette/vacations'
require 'yaml'
require 'pry'

VERSION = '0.0.10'

# Assume cards have following card title when estimated
# (8) This is the card name'
POINTS_REGEX = /\(([\d.]+)\)/

class Reviewlette
  def initialize
    @trello  = TrelloConnection.new
    @members = YAML.load_file("#{File.dirname(__FILE__)}/../config/members.yml")
    @github  = YAML.load_file("#{File.dirname(__FILE__)}/../config/github.yml")
  end

  def run
    @github['repos'].each do |repo|
      puts "Checking repository #{repo}..."
      check_repo(repo, @github['token'])
    end
  end

  def check_repo(repo_name, token)
    repo = GithubConnection.new(repo_name, token)

    unless repo.repo_exists?
      puts "Repository #{repo_name} does not exist. Check your configuration"
      return
    end

    repo.unassigned_pull_requests.each do |issue|
      issue_id    = issue[:number]
      issue_title = issue[:title]

      puts "*** Checking unassigned github pull request: #{issue_title}"
      matched = issue_title.match(/\d+[_'"]?$/)

      unless matched
        puts 'Pull request not assigned to a trello card'
        next
      end

      card_id = matched[0].to_i
      card    = @trello.find_card_by_id(card_id)

      unless card
        puts "No matching card found (id #{card_id})"
        next
      end

      puts "Found matching trello card: #{card.name}"
      reviewers = select_reviewers(card, how_many_should_review(card))

      if reviewers.empty?
        puts "Could not find a reviewer for card: #{card.name}"
        next
      end

      repo.add_assignee(issue_id, reviewers.first['github_username'])
      repo.reviewers_comment(issue_id, reviewers, card)

      @trello.comment_reviewers(card, repo_name, issue_id, reviewers)
      @trello.move_card_to_list(card, 'In review')
    end
  end

  def select_reviewers(card, number = 1)
    reviewers = @members['members']

    # remove people on vacation
    members_on_vacation = Vacations.members_on_vacation(reviewers)

    reviewers = reviewers.reject { |r| members_on_vacation.include? r['suse_username'] }

    # remove trello card owner
    reviewers = reviewers.reject { |r| card.members.map(&:username).include? r['trello_username'] }

    reviewers = reviewers.sample(number)
    puts "Selected reviewers: #{reviewers} from pool #{reviewers.map { |r| r['name'] }}" if reviewers
    reviewers
  end

  def how_many_should_review(card)
    if card.name =~ POINTS_REGEX && card.name.match(ESTIMATED_REGEX).captures.first.to_i > 5
      return 2
    end
    1
  end
end
