# encoding: US-ASCII
# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/DuplicateMethods

module PrReadline # :nodoc:
  case ::RbConfig::CONFIG['host_os'] || ::RUBY_PLATFORM
  when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    def self.windows?
      true
    end
  else
    def self.windows?
      false
    end
  end
end

# rubocop:enable Lint/DuplicateMethods
