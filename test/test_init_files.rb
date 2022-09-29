# warn_indent: true
# frozen_string_literal: true

require_relative 'test_helper'
require 'pr-readline'

class TestCapabilities < Minitest::Test # :nodoc:
  def test_init_files
    oldpwd = Dir.pwd
    Dir.chdir(__dir__)

    assert_output('', "readline: init_files/circular_1: already read or circular include\n") do
      PrReadline.rl_read_init_file('init_files/circular_1')
    end
  ensure
    Dir.chdir(oldpwd)
  end
end
