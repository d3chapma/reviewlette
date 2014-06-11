$:.unshift(File.expand_path(File.dirname(__FILE__))) unless
    $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'reviewlette/trello_connection'
require 'reviewlette/github_connection'
require 'yaml'
require 'octokit'
require 'trello'
require 'debugger'


class Trello::Card

  def assignees
    @trello_connection = Reviewlette::TrelloConnection.new
    member_ids.map{|id| @trello_connection.find_member_by_id(id)}
  end
end


module Reviewlette

  attr_accessor :trello_connection, :github_connection

  class << self
    NAMES = YAML.load_file('config/.members.yml')
    TRELLO_CONFIG1 = YAML.load_file('config/.trello.yml')
    def spin!
      @github_connection = Reviewlette::GithubConnection.new
      @trello_connection = Reviewlette::TrelloConnection.new
      @board = Trello::Board.find(TRELLO_CONFIG1['board_id'])
      @repo = 'jschmid1/reviewlette'
    end

    def main
      Reviewlette.spin!
      @github_connection.list_issues(@repo).each do |a|
        unless a[:assignee]
          @number = a[:number]
          @title = a[:title]
          @body = a[:body]
          @id = @trello_connection.find_card(@title.to_s)
          if @id then
            @card = @trello_connection.find_card_by_id(@id)
          else
            puts "@id is not set"
          end
          if @card then
            while !(@reviewer)
              @reviewer = @trello_connection.determine_reviewer(@card)
            end
          end

          if @reviewer then
            @trelloname = @reviewer.username
          else
            puts "@reviewer is not set"
          end
          @githubname = NAMES[@trelloname]
          @github_connection.add_assignee(@number, @title, @body, @githubname)
          @trello_card_url = @card.url
          @github_connection.comment_on_issue(@number, @githubname, @trello_card_url)

          begin
          @trello_connection.add_reviewer_to_card(@reviewer, @card)
          rescue
            puts 'already assigned'
          end
          @full_comment = '@' + @trelloname + ' will review ' + 'https://github.com/'+ @repo+'/issues/'+@number.to_s
          @trello_connection.comment_on_card(@full_comment, @card)
          if @github_connection.pull_merged?(@repo, @id)
            @column = @trello_connection.find_column('Done')
            @trello_connection.move_card_to_list(@card, @column)
          else
            @column = @trello_connection.find_column('In review')
            @trello_connection.move_card_to_list(@card, @column)
          end
        end
      end
      puts 'no new issue to work with'
    end
  end
end

Reviewlette.main



