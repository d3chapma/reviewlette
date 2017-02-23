require 'yaml'
require 'trello'

class Reviewlette
  class TrelloConnection

    attr_accessor :board

    def initialize
      Trello.configure do |conf|
        conf.developer_public_key = ENV['TRELLO_KEY']
        conf.member_token = ENV['TRELLO_TOKEN']
      end
      @board = Trello::Board.find(ENV['TRELLO_BOARD_ID'])
    end

    def add_reviewer_to_card(reviewer, card)
      reviewer = find_member_by_username(reviewer)
      card.add_member(reviewer)
    end

    def move_card_to_list(card, column_name)
      column = find_column(column_name)
      card.move_to_list(column)
    end

    def find_column(column_name)
      @board.lists.find { |x| x.name == column_name }
    end

    def find_member_by_username(username)
      @board.members.find { |m| m.username == username }
    end

    def find_label(label_name)
      @board.labels.find { |x| x.name == label_name }
    end

    def find_card_by_id(id)
      @board.cards.find { |c| c.short_id == id.to_i }
    end
  end
end
