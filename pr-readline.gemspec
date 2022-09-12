# warn_indent: true
# frozen_string_literal: true

libdir = File.join(File.dirname(__FILE__), 'lib')
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require_relative 'lib/pr-readline/version'

Gem::Specification.new do |spec|
  # basic information
  spec.name = 'pr-readline'
  spec.version = PrReadline::PR_READLINE_VERSION
  spec.platform = Gem::Platform::RUBY

  # description and details
  spec.summary = 'Pure-Ruby Readline Implementation'
  spec.description = 'The readline library provides a pure Ruby' \
                     ' implementation of the GNU readline C library,' \
                     ' as well as the Readline extension that ships' \
                     ' as part of the standard library.'

  # project information
  spec.homepage          = 'http://github.com/joast/pr-readline'
  spec.licenses          = ['BSD']

  # author and contributors
  spec.authors     = ['Park Heesob', 'Daniel Berger', 'Luis Lavena',
                      'Mark Somerville', 'Connor Atherton', 'Rick Ohnemus']
  # Only have my email here because all of the other authors are associated
  # with rb-readline and it appears to be dead.
  spec.email       = ['rick_ohnemus@acm.org']

  # requirements
  spec.required_ruby_version = '~> 3.0'
  spec.required_rubygems_version = '~> 3.2'

  # runtime dependencies
  spec.add_dependency 'etc', '>= 1.0'
  spec.add_dependency 'strscan', '>= 2.0'

  # development dependencies
  # spec.add_development_dependency 'minitest', '>= 5.2'
  # spec.add_development_dependency 'rake', '>= 10.0'

  # components, files and paths
  spec.files = Dir[
    '{bench,examples,lib,test}/**/*.rb',
    'CHANGES',
    'LICENSE',
    'README.md',
    'Rakefile',
    'pr-readline.gemspec',
    'setup.rb'
  ]

  spec.require_path = 'lib'

  # documentation
  spec.rdoc_options << '--main' << 'README.md' \
                    << '--title' << 'Pr-Readline - Documentation'

  spec.extra_rdoc_files = %w[CHANGES LICENSE README.md]
end
