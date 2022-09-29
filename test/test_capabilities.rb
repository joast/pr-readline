# warn_indent: true
# frozen_string_literal: true

require_relative 'test_helper'
require 'pr-readline/readline'

class TestCapabilities < Minitest::Test # :nodoc:
  def test_capabilities
    PrReadline.term_capabilities
    File.open('/tmp/caps', 'wt') do |f|
      f.puts PrReadline.instance_variables.sort
    end
  end
end
