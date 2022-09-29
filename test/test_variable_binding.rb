# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength

require_relative 'test_helper'
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
      old_value = PrReadline.rl_variable_value(bv)

      PrReadline.rl_variable_bind(bv, 'on')
      assert_equal('on', PrReadline.rl_variable_value(bv), bv)

      PrReadline.rl_variable_bind(bv, 'off')
      assert_equal('off', PrReadline.rl_variable_value(bv), bv)

      PrReadline.rl_variable_bind(bv.upcase, 'ON')
      assert_equal('on', PrReadline.rl_variable_value(bv), bv)

      PrReadline.rl_variable_bind(bv.upcase, 'OFF')
      assert_equal('off', PrReadline.rl_variable_value(bv), bv)

      PrReadline.rl_variable_bind(bv.upcase, 'ON')
      PrReadline.rl_variable_bind(bv.upcase, 'junk')
      assert_equal('off', PrReadline.rl_variable_value(bv), bv)

      PrReadline.rl_variable_bind(bv.upcase, 'OFF')
      PrReadline.rl_variable_bind(bv.upcase, '')
      assert_equal('on', PrReadline.rl_variable_value(bv), bv)

      PrReadline.rl_variable_bind(bv.upcase, 'OFF')
      PrReadline.rl_variable_bind(bv.upcase, nil)
      assert_equal('on', PrReadline.rl_variable_value(bv), bv)

      PrReadline.rl_variable_bind(bv, old_value)
      assert_equal(old_value, PrReadline.rl_variable_value(bv), bv)
    end
  end

  def test_bell_style
    vn = 'bell-style'
    old_value = PrReadline.rl_variable_value(vn)

    assert(PrReadline.rl_variable_bind(vn, 'visible'))
    assert_equal('visible', PrReadline.rl_variable_value(vn), vn)

    assert(PrReadline.rl_variable_bind(vn, old_value))
    assert_equal(old_value, PrReadline.rl_variable_value(vn), vn)
  end

  def test_comment_begin
    vn = 'comment-begin'
    old_value = PrReadline.rl_variable_value(vn)
    assert_equal(PrReadline::RL_COMMENT_BEGIN_DEFAULT, old_value, vn)

    assert(PrReadline.rl_variable_bind(vn, '*@'))
    assert_equal('*@', PrReadline.rl_variable_value(vn), vn)

    assert(PrReadline.rl_variable_bind(vn, old_value))
    assert_equal(old_value, PrReadline.rl_variable_value(vn), vn)

    assert_output('', "readline: comment-begin: could not set value to ''\n") do
      refute(PrReadline.rl_variable_bind(vn, nil))
    end

    assert_output('', "readline: comment-begin: could not set value to ''\n") do
      refute(PrReadline.rl_variable_bind(vn, ''))
    end

    assert_equal(old_value, PrReadline.rl_variable_value(vn), vn)
  end
end
