require 'reviewlette/trello_connection'
require 'reviewlette/github_connection'
require 'yaml'

class Reviewlette
  def initialize(testers:, reviewers:)
    @trello  = TrelloConnection.new
    @reviewers = reviewers
    @testers = testers
  end

  def run
    comment_for_review
  end

  def comment_for_review
    col = @trello.find_column('Under Review')
    col.cards.each do |card|
      comment_reviewers(card, @reviewers, 'Reviewer Assigned')
    end
  end

  def comment_for_test
    col = @trello.find_column('Testing')
    col.cards.each do |card|
      comment_testers(card, @testers, 'Tester Assigned')
    end
  end

  def comment_reviewers(card, reviewers, marker_label)
    return if card.labels.any? { |l| l.name == marker_label }

    handles = random_handles(card, reviewers)
    card.add_comment("#{handles}, you have been randomly chosen to review this card")

    label = @trello.find_label(marker_label)
    card.add_label(label)
  end

  def comment_testers(card, testers, marker_label)
      return if card.labels.any? { |l| l.name == marker_label }

      handles = random_handles(card, testers)
      card.add_comment("#{handles}, you have been randomly chosen to test this card")

      label = @trello.find_label(marker_label)
      card.add_label(label)
    end

  def random_handles(card, handles, count = 1)
    members = card.members.map(&:username)
    available_handles = handles.reject { |r| members.include? r.trello_handle }
    available_handles.sample(count).map do |h|
      "@#{h.trello_handle}"
    end.join(' and ')
  end
end
