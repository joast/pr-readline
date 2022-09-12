# warn_indent: true
# frozen_string_literal: true

unless defined? PrReadline
  if defined? Readline
    warn 'Removing old Readline module - redefined by pr-readline.' if $DEBUG
    Object.send(:remove_const, :Readline)
  end

  require_relative 'readline'
end
