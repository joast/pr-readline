#!/usr/bin/env ruby
# encoding: US-ASCII
# warn_indent: true
# frozen_string_literal: true

require 'fiddle'
require 'fiddle/import'
require 'set'
require 'strscan'
require 'amazing_print'

# rubocop:disable Layout/SpaceBeforeSemicolon
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ModuleLength
# rubocop:disable Style/Semicolon

module PrReadline # :nodoc:
  class TerminfoError < StandardError; end

  module Terminfo # :nodoc:
    extend Fiddle::Importer

    module Lib # :nodoc:
      extend Fiddle::Importer

      def self.add_libraries(libs, filename)
        scanner = StringScanner.new(File.read(filename, mode: 'rt'))
        new_libs = []

        while scanner.scan_until(/^INPUT\s*[(]\s*/)
          while (fn = scanner.scan_until(/(?=\s+|[,)])/))
            new_libs << fn unless fn.start_with?('-l')
            scanner.skip(/\s+|([,)]\s*)/)
          end
        end

        libs.prepend(*new_libs) unless new_libs.empty?
      rescue SystemCallError
        # ignore file errors
      end

      @curses_lib = nil

      def self.find_library
        libs = %w[
          libncursesw.so libcursesw.so libncurses.so libcurses.so libtinfo.so
          libncursesw.dylib libcursesw.dylib libncurses.dylib libcurses.dylib
          cygncursesw-10.dll cygncurses-10.dll
        ]

        seen = Set.new

        while (lib = libs.shift)
          next if seen.include?(lib)

          seen.add(lib)

          begin
            @curses_lib = Fiddle::Handle.new(lib)
            break unless @curses_lib.nil?
          rescue Fiddle::DLError => e
            if e.message =~ /^([^:]+):\s*(?=file too short|invalid ELF header)/
              add_libraries(libs, Regexp.last_match(1))
            end
          end
        end
      end

      find_library
      dlload @curses_lib unless @curses_lib.nil?

      extern 'int    mvcur(int, int, int, int)'
      extern 'int    putp(const char *)'
      extern 'int    restartterm(char *, int, int *)'
      extern 'int    setupterm(char *, int, int *)'
      extern 'int    tigetflag(char *)'
      extern 'int    tigetnum(char *)'
      extern 'char * tigetstr(char *)'
      extern 'char * tiparm(const char *, ...)'
      extern 'int    tputs(const char *, int, int (*)(int))'
    end

    def mvcur(oldrow, oldcol, newrow, newcol)
      unless oldrow.is_a?(Integer)
        raise TerminfoError, "oldrow isn't an Integer: #{oldrow.class}"
      end

      unless oldcol.is_a?(Integer)
        raise TerminfoError, "oldcol isn't an Integer: #{oldcol.class}"
      end

      unless newrow.is_a?(Integer)
        raise TerminfoError, "newrow isn't an Integer: #{newrow.class}"
      end

      unless newcol.is_a?(Integer)
        raise TerminfoError, "newcol isn't an Integer: #{newcol.class}"
      end

      Lib.mvcur(oldrow, oldcol, newrow, newcol).zero?
    end

    def putp(str)
      unless str.is_a?(String)
        raise TerminfoError, "argument isn't a String: #{str.inspect}"
      end

      Lib.putp(str).zero?
    end

    def restartterm(term, fildes = 1)
      setup_or_restart(check_term(term), fildes) do |t, fd, errret|
        Lib.restartterm(t, fd, errret)
      end
    end

    def setterm(term)
      setupterm(term, 1)
    end

    def setupterm(term, fildes = 1)
      setup_or_restart(check_term(term), fildes) do |t, fd, errret|
        Lib.setupterm(t, fd, errret)
      end
    end

    def tigetflag(capname)
      unless capname.is_a?(String)
        raise TerminfoError, "capname isn't a String: #{capname.inspect}"
      end

      flag = Lib.tigetflag(capname)

      if flag == -1
        raise TerminfoError, "#{capname.inspect} isn't a boolean capability"
      end

      !flag.zero?
    end

    def tigetnum(capname)
      unless capname.is_a?(String)
        raise TerminfoError, "capname isn't a String: #{capname.inspect}"
      end

      num = Lib.tigetnum(capname)

      case num
      when -2
        raise TerminfoError, "#{capname.inspect} isn't a numeric capability"
      when -1
        nil
      else
        num
      end
    end

    def tigetstr(capname)
      unless capname.is_a?(String)
        raise TerminfoError, "capname isn't a String: #{capname.inspect}"
      end

      cap = Lib.tigetstr(capname)

      case retval_to_int(cap)
      when -1
        raise TerminfoError,
              "tigetstr: #{capname.inspect} isn't a string capability"
      when 0, nil
        nil
      else
        cap.to_s
      end
    end

    INT_MAX = (2**((Fiddle::SIZEOF_INT * 8) - 1)) - 1
    INT_MIN = -INT_MAX - 1

    def tiparm(str, *args)
      unless str.is_a?(String)
        raise TerminfoError, "need a String: #{str.inspect}"
      end

      int_args = []

      args.each do |arg|
        if arg < INT_MIN || arg > INT_MAX
          raise TerminfoError, "integer out of range: #{arg}"
        end

        int_args << Fiddle::TYPE_INT << arg
      end

      new_str = Lib.tiparm(str, *int_args)

      case retval_to_int(new_str)
      when -1
        raise TerminfoError,
              "tiparm: #{capname.inspect} isn't a string capability"
      when 0, nil
        nil
      else
        new_str.to_s
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity

    def tputs(str, affcnt: 1, putc: nil, &block)
      unless str.is_a?(String)
        raise TerminfoError, "argument isn't a String: #{str.inspect}"
      end

      affcnt = 1 if affcnt.nil? || affcnt.zero?

      unless str.is_a?(String)
        raise TerminfoError, "argument isn't an Integer: #{str.inspect}"
      end

      if affcnt <= 0 || affcnt > INT_MAX
        raise TerminfoError, "affcnt out of range: #{affcnt}"
      end

      if putc.nil?
        if block
          unless block.arity == 1
            raise TerminfoError, "block has arity of #{block.arity}, need 1"
          end

          callback = block
        else
          callback = proc { |int| print int.chr ; int }
        end
      elsif putc.is_a?(Proc)
        unless putc.arity == 1
          raise TerminfoError, "proc has arity of #{putc.arity}, need 1"
        end

        callback = putc
      else
        raise TerminfoError, "don't know how to handle putc: #{putc.inspect}"
      end

      putchar = Class.new(Fiddle::Closure) do
        attr_accessor :callback

        def call(int)
          @callback.call(int)
        end
      end.new(Fiddle::TYPE_INT, [Fiddle::TYPE_INT])

      putchar.callback = callback

      ret = Lib.tputs(str, affcnt, putchar)

      unless ret.zero? || ret == -1
        raise TerminfoError, "tputs: unknown return value: #{ret}"
      end

      ret.zero?
    end

    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    module_function :mvcur
    module_function :putp
    module_function :restartterm
    module_function :setterm
    module_function :setupterm
    module_function :tigetflag
    module_function :tigetnum
    module_function :tigetstr
    module_function :tiparm
    module_function :tputs

    def self.check_term(term)
      term = '' if term.nil?

      unless term.is_a?(String)
        raise TerminfoError, "term isn't a String or nil: #{str.inspect}"
      end

      term.strip.empty? ? ENV.fetch?('TERM', 'dumb') : term
    end

    def self.retval_to_int(retval)
      retval.is_a?(Numeric) ? retval : Integer(retval)
    rescue ArgumentError, FloatDomainError, Math::DomainError
      nil
    end

    def self.setup_or_restart(term, fildes)
      errret_int = Fiddle::Pointer.malloc(Fiddle::SIZEOF_INT)
      ret = yield term, fildes, errret_int

      return if ret.zero?
      raise TerminfoError, "unknown return value: #{ret}" unless ret == -1

      errret = errret_int[0, Fiddle::SIZEOF_INT].unpack1('i')

      case errret
      when 1
        raise TerminfoError, 'Hardcopy terminal'
      when 0
        raise TerminfoError, 'Terminal not found or generic'
      when -1
        raise TerminfoError, 'terminfo database not found'
      else
        raise TerminfoError, "unknown error: #{errret}"
      end
    end
  end
end

# rubocop:enable Style/Semicolon
# rubocop:enable Metrics/ModuleLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Layout/SpaceBeforeSemicolon
