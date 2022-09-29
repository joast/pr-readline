# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/LineLength

require_relative 'test_helper'
require 'pr-readline'

class TestInitFiles < Minitest::Test # :nodoc:
  def setup
    @run_dir = Dir.pwd
    Dir.chdir(__dir__)
  end

  def test_init_files
    assert_output('', "readline: init_files/circular_1: already read or circular include\n") do
      PrReadline.rl_read_init_file('init_files/circular_1')
    end
  end

  def teardown
    Dir.chdir(@run_dir)
  end
end
