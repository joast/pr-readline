# warn_indent: true
# frozen_string_literal: true

unless defined? PrReadline
  if defined? Readline
    if $DEBUG
      $stderr.puts 'Removing old Readline module - redefined by pr-readline.'
    end

    Object.send(:remove_const, :Readline)
  end

  require_relative 'readline'
end
