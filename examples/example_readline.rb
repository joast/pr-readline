# warn_indent: true
# frozen_string_literal: true

require 'pr-readline'

loop do
  line = Readline.readline('> ')
  Readline::HISTORY.push(line)
  puts "You typed: #{line}"
  break if line == 'quit'
end
