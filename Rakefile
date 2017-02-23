require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc 'Run console loaded with gem'
task :console do
  require 'irb'
  require 'irb/completion'
  require 'byebug'
  require 'awesome_print'
  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
  require 'reviewlette'
  ARGV.clear
  IRB.start
end

class User
  attr_reader :trello_handle, :github_handle

  def initialize(trello_handle, github_handle)
    @trello_handle = trello_handle
    @github_handle = github_handle
  end
end

REVIEWERS = [
  User.new('davechapman4', 'd3chapma'),
  User.new('georgesantoineassi', 'GAntoine'),
  User.new('nicholashorton', 'Nicholas-Horton'),
  User.new('urigorelik', 'uri')
]

TESTERS = [
  User.new('christophersisto', ''),
  User.new('kailcarruthers2', '')
]


desc 'Run task to check all PRs for reviewers'
task :check do
  require 'byebug'
  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')
  require 'reviewlette'

  Reviewlette.new(reviewers: REVIEWERS, testers: TESTERS).run
end
