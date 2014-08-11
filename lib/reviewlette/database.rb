require 'sequel'

module Reviewlette

  class Database

    DATABASE = Sequel.connect('sqlite://test.db')

    attr_accessor :reviewer, :reviews

    def initialize
      @reviewer = DATABASE.from(:reviewer)
      @reviews = DATABASE.from(:reviews)
    end

    def count_up(reviewer)
      pr_reviewer = @reviewer.where(:trello_name => reviewer).select(:trello_name).first.values.first
      counter = @reviewer.where(:trello_name => pr_reviewer).select(:reviews).first.values.first
      @reviewer.where(:trello_name => reviewer).update(:reviews => counter.next)
    end

    def add_pr_to_db(pr_name, reviewer)
      @reviews.insert(:name => pr_name, :reviewer => reviewer)
      count_up(reviewer)
    end

    def get_users_tel_entries
      @reviewer.map([:tel_name]).flatten.select{|user| user unless user.nil?}
    end

    def get_users_gh_entries
      @reviewer.map([:gh_name]).flatten.select{|user| user unless user.nil?}
    end

    def get_users_trello_entries
      @reviewer.where(:vacation => 'false').map([:trello_name]).flatten.select{|user| user unless user.nil?}
    end

    def count_reviews(reviewer)
      @reviews.where(:reviewer => reviewer).count
    end

    def find_gh_name_by_trello_name(trello_name)
      @reviewer.where(:trello_name => trello_name).select(:gh_name).first.values.first
    end

    def set_vacation_flag(reviewer, state)
      @reviewer.where(:tel_name => reviewer).update(:vacation => state)
    end

  end
end
