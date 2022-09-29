# warn_indent: true
# frozen_string_literal: true

require_relative 'test_helper'
require 'pr-readline/readline'

class TestCapabilities < Minitest::Test # :nodoc:
  def test_capabilities
    PrReadline.term_capabilities
  end
end
