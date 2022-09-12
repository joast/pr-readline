# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Layout/LineLength

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/../lib/"
require 'pr-readline'
require 'benchmark'

N = 100_000

Benchmark.bmbm do |x|
  x.report do
    N.times { PrReadline._rl_adjust_point('a', 0) }
  end

  x.report do
    N.times { PrReadline._rl_adjust_point('a', 1) }
  end

  x.report do
    N.times { PrReadline._rl_adjust_point('aaaaaaaaaaaaaaaaaaaaa', 0) }
  end

  x.report do
    N.times { PrReadline._rl_adjust_point('aaaaaaaaaaaaaaaaaaaaa', 40) }
  end

  x.report do
    N.times { PrReadline._rl_adjust_point('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 0) }
  end

  x.report do
    N.times { PrReadline._rl_adjust_point('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 40) }
  end
end
