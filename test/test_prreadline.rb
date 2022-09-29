# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Metrics/AbcSize
# rubocop:disable Layout/LineLength

require_relative 'test_helper'
require 'pr-readline'

class TestPrReadline < Minitest::Test # :nodoc:
  def test_versions
    assert_equal('5.2', PrReadline::RL_LIBRARY_VERSION)
    assert_equal(0x0502, PrReadline::RL_READLINE_VERSION)
  end

  if defined?(Encoding)
    def test_rl_adjust_point
      encoding_name = PrReadline.instance_variable_get(:@encoding_name)
      PrReadline.instance_variable_set(:@encoding_name, Encoding.find('UTF-8'))

      assert_equal(0, PrReadline._rl_adjust_point((+'a').force_encoding('ASCII-8BIT'), 0))
      assert_equal(0, PrReadline._rl_adjust_point((+'a').force_encoding('ASCII-8BIT'), 1))
      assert_equal(0, PrReadline._rl_adjust_point((+'a' * 40).force_encoding('ASCII-8BIT'), 0))
      assert_equal(0, PrReadline._rl_adjust_point((+'a' * 40).force_encoding('ASCII-8BIT'), 40))
      assert_equal(2, PrReadline._rl_adjust_point(("\u3042" * 10).force_encoding('ASCII-8BIT'), 1))
      assert_equal(1, PrReadline._rl_adjust_point(("\u3042" * 15).force_encoding('ASCII-8BIT'), 38))
    ensure
      PrReadline.instance_variable_set(:@encoding_name, encoding_name)
    end
  end
end
