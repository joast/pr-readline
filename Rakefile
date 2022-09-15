# warn_indent: true
# frozen_string_literal: true

require 'rake/testtask'
require 'bundler/gem_tasks'
require 'git/lint/rake/setup'
require 'English'

file 'Gemfile.lock' => ['pr-readline.gemspec'] do
  puts 'Running "bundle check"...' if verbose
  system('bundle', 'check')

  unless $CHILD_STATUS&.exited? && $CHILD_STATUS&.success?
    abort '"bundle check" failed'
  end

  # Make sure Gemfile.lock's timestamps are updated to keep this rule from
  # again until pr-readline.gemspec is updated.
  now = Time.now
  File.utime(now, now, 'Gemfile.lock')
end

Rake::TestTask.new do |t|
  t.libs << 'test'

  t.warning = true
  t.verbose = true
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task rubocop: 'Gemfile.lock' # rubocop:disable Rake/Desc

desc 'The default is to run rubocop and tests if rubocop succeeds.'
task default: %i[rubocop test]
