# encoding: US-ASCII
# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ModuleLength
# rubocop:disable Metrics/PerceivedComplexity

require 'English'

module PrReadline # :nodoc:
  class ScreenError < StandardError; end

  # TODO: need some docs
  module Screen # :nodoc:
    # Default terminal size. Change with default_size(rows, columns).
    @default_size = [24, 80]

    def default_size
      @default_size
    end

    def default_size=(rows, columns)
      begin
        lines = Integer(rows)
        raise ArgumentError if out_of_range(lines)
      rescue ArgumentError, FloatDomainError, Math::DomainError
        raise ScreenError, "invalid value for default lines/rows: #{rows}"
      end

      begin
        cols = Integer(columns)
        raise ArgumentError if out_of_range(cols)
      rescue ArgumentError, FloatDomainError, Math::DomainError
        raise ScreenError, "invalid value for default columns: #{columns}"
      end

      @default_size = [lines, cols]
    end

    module_function :default_size, :default_size=

    # Copy a few environment variable values
    @_env = {
      COLUMNS: ENV.fetch('COLUMNS', '').strip,
      ROWS: ENV.fetch('ROWS', '').strip,
      ANSICON: ENV.fetch('ANSICON', '').strip
    }

    def self.try_everything(tty, verbose, ignore_env, prefer_env)
      if prefer_env && !ignore_env && (size = size_from_env(tty, verbose))
        # don't change @_size_from -- size might change later
      elsif (size = size_from_ioctl(tty, verbose))
        @_size_from = method(:size_from_ioctl)
      elsif (size = size_from_io_console(tty, verbose))
        @_size_from = method(:size_from_io_console)
      elsif (size = size_from_stty(tty, verbose))
        @_size_from = method(:size_from_stty)
      elsif (size = size_from_win_api(tty, verbose))
        @_size_from = method(:size_from_win_api)
      elsif (size = size_from_ansicon(tty, verbose))
        @_size_from = method(:size_from_ansicon)
      elsif !ignore_env && (size = size_from_env(tty, verbose))
        @_size_from = method(:size_from_env)
      elsif (size = size_from_terminfo(tty, verbose))
        @_size_from = method(:size_from_terminfo)
      else
        # does anything ever make it this far?
        size = size_from_default(tty, verbose) # a.k.a. @default_size
        @_size_from = method(:size_from_default)
      end

      size
    end

    private_class_method :try_everything

    # Method called to determine size. Try everything the first time this is
    # called. After that, the successful method will be called.
    @_size_from = nil

    def size(tty, ignore_env: false, prefer_env: false, verbose: false)
      @_size = if @_size_from
                 @_size_from.call(tty, verbose)
               else
                 try_everything(tty, verbose, ignore_env, prefer_env)
               end
    end

    module_function :size

    def self.convert(lines, columns)
      l = Integer(lines)
      c = Integer(columns)
      [l, c] unless out_of_range(l) || out_of_range(c)
    rescue ArgumentError, FloatDomainError, Math::DomainError
      nil
    end

    private_class_method :convert

    def self.out_of_range(value)
      value <= 0 || value > 32_767
    end

    private_class_method :out_of_range

    def self.size_from_ansicon(_tty, _verbose)
      return unless @_env['ANSICON'] =~ /\((\d+)x(\d+)\)/

      convert(Regexp.last_match(2), Regexp.last_match(1))
    end

    private_class_method :size_from_ansicon

    def self.size_from_default(_tty, _verbose)
      @default_size
    end

    private_class_method :size_from_default

    def self.size_from_env(_tty, _verbose)
      convert(@_env['LINES'].empty? ? @_env['ROWS'] : @_env['LINES'],
              @_env['COLUMNS'])
    end

    private_class_method :size_from_env

    def self.size_from_io_console(tty, verbose)
      require 'io/console' unless IO.method_defined?(:winsize)

      return unless tty.tty? && tty.respond_to?(:winsize)

      size = tty.winsize
      convert(size[0], size[1])
    rescue Errno::EOPNOTSUPP
      # no support for winsize on output
    rescue LoadError
      warn 'missing native io/console support or io-console gem' if verbose
    end

    private_class_method :size_from_io_console

    if PrReadline.windows?
      def self.size_from_ioctl(_tty, _verbose)
        nil
      end
    else
      TIOCGWINSZ = 0x5413 # linux
      TIOCGWINSZ_PPC = 0x40087468 # macos, freedbsd, netbsd, openbsd
      TIOCGWINSZ_SOL = 0x5468 # solaris

      def self.size_from_ioctl(_tty, _verbose)
        format = 'SSSS'
        buffer = ([0] * format.size).pack(format)

        if ioctl?(TIOCGWINSZ, buffer) ||
           ioctl?(TIOCGWINSZ_PPC, buffer) ||
           ioctl?(TIOCGWINSZ_SOL, buffer)
          rows, cols = buffer.unpack(format)[0..1]
          convert(rows, cols)
        end
      end

      def self.ioctl?(control, buf)
        begin
          return true if $stdout.ioctl(control, buf) >= 0
        rescue SystemCallError
          # ignore
        end

        begin
          return true if $stdin.ioctl(control, buf) >= 0
        rescue SystemCallError
          # ignore
        end

        begin
          return true if $stderr.ioctl(control, buf) >= 0
        rescue SystemCallError
          # ignore
        end

        false
      end

      private_class_method :ioctl?
    end

    private_class_method :size_from_ioctl

    def self.size_from_stty(tty, _verbose)
      # stty does its thing using file descriptor 0. could do something fancy
      # to make this work if tty isn't fileno 0, but why bother?
      return unless tty&.fileno&.zero? && tty.tty?

      out = `stty size 2>/dev/null`

      return unless
        $CHILD_STATUS&.exited? && $CHILD_STATUS&.success? && !out.strip.empty?

      size = out.split(nil, 2)
      convert(size[0], size[1])
    end

    private_class_method :size_from_stty

    def self.size_from_terminfo(_tty, _verbose)
      convert(Terminfo.tigetnum('lines'), Terminfo.tigetnum('cols'))
    rescue TerminfoError
      nil
    end

    private_class_method :size_from_terminfo

    if PrReadline.windows?
      STDOUT_HANDLE = 0xFFFFFFF5

      def self.size_from_win_api(_tty, verbose)
        require 'fiddle'

        kernel32 = Fiddle::Handle.new('kernel32')

        get_std_handle =
          Fiddle::Function.new(kernel32['GetStdHandle'],
                               [-Fiddle::TYPE_INT], Fiddle::TYPE_INT)

        get_console_buffer_info =
          Fiddle::Function.new(kernel32['GetConsoleScreenBufferInfo'],
                               [Fiddle::TYPE_LONG, Fiddle::TYPE_VOIDP],
                               Fiddle::TYPE_INT)

        format        = 'SSSSSssssSS'
        buffer        = ([0] * format.size).pack(format)
        stdout_handle = get_std_handle.call(STDOUT_HANDLE)

        get_console_buffer_info.call(stdout_handle, buffer)
        _, _, _, _, _, left, top, right, bottom, = buffer.unpack(format)

        convert(bottom - top + 1, right - left + 1)
      rescue LoadError
        warn 'no native fiddle module found' if verbose
      rescue Fiddle::DLError
        warn 'not windows or kernel32 lib not found' if verbose
      end
    else
      def self.size_from_win_api(_tty, _verbose)
        nil
      end
    end

    private_class_method :size_from_win_api
  end
end
