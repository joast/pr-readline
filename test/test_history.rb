# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Style/BlockDelimiters

require_relative 'test_helper'
require 'pr-readline/readline'

class TestHistory < Minitest::Test # :nodoc:
  # PrReadline::HISTORY_WORD_DELIMITERS.inspect
  # => " \t\n;&()|<>"
  # PrReadline::HISTORY_QUOTE_CHARACTERS   = "\"'`"
  # => "\"'`"
  def test_history_arg_extract
    assert_raises(RuntimeError) {
      PrReadline.history_arg_extract('!', '$', 'one two three')
    }

    assert_raises(RuntimeError) {
      PrReadline.history_arg_extract('$', '!', 'one two three')
    }

    assert_equal('one', PrReadline.history_arg_extract('$', '$', 'one'))
    assert_equal('three',
                 PrReadline.history_arg_extract('$', '$', 'one two three'))
    assert_equal('two\\ three',
                 PrReadline.history_arg_extract('$', '$', 'one two\\ three'))
    assert_equal('three',
                 PrReadline.history_arg_extract('$', '$', 'one two;three'))
    assert_equal('two\\;three',
                 PrReadline.history_arg_extract('$', '$', 'one two\\;three'))

    assert_equal("'two three'",
                 PrReadline.history_arg_extract('$', '$', "one 'two three'"))
    assert_equal('`two three`',
                 PrReadline.history_arg_extract('$', '$', 'one `two three`'))
    assert_equal("three\\'",
                 PrReadline.history_arg_extract('$', '$',
                                                "one \\'two three\\'"))
    assert_equal('`one`', PrReadline.history_arg_extract('$', '$', '`one`'))

    assert_equal("three'",
                 PrReadline.history_arg_extract('$', '$', "one two three'"))
    assert_equal('three',
                 PrReadline.history_arg_extract('$', '$', "one two' three"))
    assert_equal("'two three '",
                 PrReadline.history_arg_extract('$', '$', "one 'two three '"))
  end
end
