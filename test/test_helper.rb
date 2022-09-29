# warn_indent: true
# frozen_string_literal: true

unless defined?(PRE_TEST_STTY_SETTINGS)
  PRE_TEST_STTY_SETTINGS = `stty -g`.freeze

  at_exit { `stty #{PRE_TEST_STTY_SETTINGS}` }
end

require 'minitest/autorun'
require 'amazing_print'
