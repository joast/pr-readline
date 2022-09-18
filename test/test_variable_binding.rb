# warn_indent: true
# frozen_string_literal: true

require 'minitest/autorun'
require 'pr-readline/readline'

class TestVariableBinding < Minitest::Test # :nodoc:
  def test_boolean_variables
    %w[
      bind-tty-special-chars
      blink-matching-paren
      byte-oriented
      colored-completion-prefix
      colored-stats
      completion-ignore-case
      completion-map-case
      convert-meta
      disable-completion
      echo-control-characters
      enable-bracketed-paste
      enable-keypad
      enable-meta-key
      expand-tilde
      history-preserve-point
      horizontal-scroll-mode
      input-meta
      mark-directories
      mark-modified-lines
      mark-symlinked-directories
      match-hidden-files
      menu-complete-display-prefix
      meta-flag
      output-meta
      page-completions
      prefer-visible-bell
      print-completions-horizontally
      revert-all-at-newline
      show-all-if-ambiguous
      show-all-if-unmodified
      show-mode-in-prompt
      skip-completed-text
      visible-stats
    ].each do |bv|
      # TODO: really shouldn't be doing this without testing rl_variable_value
      # first
      old_value = PrReadline::rl_variable_value(bv)

      PrReadline::rl_variable_bind(bv, 'on')
      assert_equal(PrReadline::rl_variable_value(bv), 'on', bv)

      PrReadline::rl_variable_bind(bv, 'off')
      assert_equal(PrReadline::rl_variable_value(bv), 'off', bv)

      PrReadline::rl_variable_bind(bv.upcase, 'ON')
      assert_equal(PrReadline::rl_variable_value(bv), 'on', bv)

      PrReadline::rl_variable_bind(bv.upcase, 'OFF')
      assert_equal(PrReadline::rl_variable_value(bv), 'off', bv)

      PrReadline::rl_variable_bind(bv.upcase, 'ON')
      PrReadline::rl_variable_bind(bv.upcase, 'junk')
      assert_equal(PrReadline::rl_variable_value(bv), 'off', bv)

      PrReadline::rl_variable_bind(bv.upcase, 'OFF')
      PrReadline::rl_variable_bind(bv.upcase, '')
      assert_equal(PrReadline::rl_variable_value(bv), 'on', bv)

      PrReadline::rl_variable_bind(bv.upcase, 'OFF')
      PrReadline::rl_variable_bind(bv.upcase, nil)
      assert_equal(PrReadline::rl_variable_value(bv), 'on', bv)

      PrReadline::rl_variable_bind(bv, old_value)
      assert_equal(PrReadline::rl_variable_value(bv), old_value, bv)
    end
  end
end
