require 'reviewlette/trello_connection'
require 'reviewlette/github_connection'
require 'yaml'

ENV['TRELLO_BOARD_ID'] = 'sYFl6KwF'
ENV['TRELLO_KEY'] =      '0e1ff48869eaf4dd6b31631a5c506f9f'
ENV['TRELLO_TOKEN'] =    'b32a083349171ba8b236977c3ad531d5656488f5645ff4762dfa300963b6b305'

class Reviewlette
  def initialize(testers:, reviewers:)
    @trello  = TrelloConnection.new
    @reviewers = reviewers
    @testers = testers
  end

  def run
    check_under_review
  end

  def check_under_review
    col = @trello.find_column('Under Review')
    col.cards.each do |card|
      check_for_pr(card)
      comment_reviewers(card, @reviewers, 'Reviewer Assigned')
    end
  end

  def check_for_pr(card)
    attachment = card.attachments.detect { |a| a.url.match(/github/) }
    if attachment
      add_review_link(card, attachment)
    else
      remind_owners_of_pr(card)
    end
  end

  def add_review_link(card, attachment)
    has_link = card.desc.match(/herokuapp/)
    unless has_link
      _, pr = attachment.name.match(/^#(\w+)/).to_a
      card.desc = "# https://teldiod3test-pr-#{pr}.herokuapp.com \n\n ----------\n\n #{card.desc}"
      card.save
    end
  end

  def remind_owners_of_pr(card)
    owners = card.members.map(&:username)
    handles = join_handles(owners)
    card.add_comment("#{handles}, please attach a pull request using the GitHub button on the right.")
  end

  def comment_reviewers(card, reviewers, marker_label)
    return if card.labels.any? { |l| l.name == marker_label }

    handles = random_handles(card, reviewers)
    card.add_comment("#{handles}, you have been randomly chosen to review this card")

    label = @trello.find_label(marker_label)
    card.add_label(label)
  end

  def random_handles(card, handles, count = 1)
    members = card.members.map(&:username)
    available_handles = handles.reject { |r| members.include? r.trello_handle }
    join_handles(available_handles.sample(count).map(&:trello_handle))
  end

  def join_handles(handles)
    handles.map { |handle| "@#{handle}" }.join(' and ')
  end
end
