# warn_indent: true
# frozen_string_literal: true

require 'pr-readline'

loop do
  line = Readline.readline('> ')
  Readline::HISTORY.push(line)
  puts "You typed: #{line}"
  exit if line.match?(/\A(exit|quit)\z/i)
end
