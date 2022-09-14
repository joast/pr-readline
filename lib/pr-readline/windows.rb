# encoding: US-ASCII
# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Style/MutableConstant
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength

module PrReadline # :nodoc:
  if RUBY_VERSION < '1.9.1'
    require 'Win32API'
  else
    require 'fiddle'

    class Win32API # :nodoc:
      DLL = {}

      TYPEMAP = {
        '0' => Fiddle::TYPE_VOID,
        'S' => Fiddle::TYPE_VOIDP,
        'I' => Fiddle::TYPE_LONG
      }

      CALL_TYPE_TO_ABI = {
        :stdcall => 1,
        :cdecl => 1,
        nil => 1
      } # Taken from Fiddle::Importer

      def initialize(dllname, func, import, _export, calltype = :stdcall)
        @proto = import.join.tr('VPpNnLlIi', '0SSI').chomp('0').chars
        handle = DLL[dllname] ||= Fiddle.dlopen(dllname)
        @func =
          Fiddle::Function.new(handle[func], TYPEMAP.values_at(*@proto),
                               CALL_TYPE_TO_ABI[calltype])
      end

      def call(*args)
        args.each_with_index do |x, i|
          # TODO: is this even necessary?
          if @proto[i] == 'S' && !x.is_a?(Fiddle::Pointer)
            args[i], = [x.zero? ? nil : x].pack('p').unpack('l!*')
          end

          args[i], = [x].pack('I').unpack('i') if @proto[i] == 'I'
        end

        @func.call(*args).to_i || 0
      end

      alias Call call
    end
  end

  STD_OUTPUT_HANDLE = -11
  STD_INPUT_HANDLE  = -10
  KEY_EVENT = 1
  VK_SHIFT = 0x10
  VK_MENU = 0x12
  VK_LMENU = 0xA4
  VK_RMENU = 0xA5

  LEFT_CTRL_PRESSED         = 0x0008
  RIGHT_CTRL_PRESSED        = 0x0004
  LEFT_ALT_PRESSED          = 0x0002
  RIGHT_ALT_PRESSED         = 0x0001

  @getch = Win32API.new('msvcrt', '_getch', [], 'I')
  @kbhit = Win32API.new('msvcrt', '_kbhit', [], 'I')

  # rubocop:disable Naming/VariableName
  @GetStdHandle = Win32API.new('kernel32', 'GetStdHandle', %w[L], 'L')
  @SetConsoleCursorPosition =
    Win32API.new('kernel32', 'SetConsoleCursorPosition', %w[L L], 'L')
  @GetConsoleScreenBufferInfo =
    Win32API.new('kernel32', 'GetConsoleScreenBufferInfo', %w[L P], 'L')
  @FillConsoleOutputCharacter =
    Win32API.new('kernel32', 'FillConsoleOutputCharacter', %w[L L L L P], 'L')
  @ReadConsoleInput =
    Win32API.new('kernel32', 'ReadConsoleInput', %w[L P L P], 'L')
  @MessageBeep = Win32API.new('user32', 'MessageBeep', %w[L], 'L')
  @GetKeyboardState = Win32API.new('user32', 'GetKeyboardState', %w[P], 'L')
  @GetKeyState = Win32API.new('user32', 'GetKeyState', %w[L], 'L')
  @hConsoleHandle = @GetStdHandle.Call(STD_OUTPUT_HANDLE)
  @hConsoleInput =  @GetStdHandle.Call(STD_INPUT_HANDLE)
  # rubocop:enable Naming/VariableName

  @pending_count = 0
  @pending_key = nil

  @encoding =
    begin
      case `chcp`.scan(/\d+$/).first.to_i
      when 936, 949, 950, 51_932, 51_936, 50_225
        'E'
      when 932, 50_220, 50_221, 20_222
        'S'
      when 65_001
        'U'
      else
        'N'
      end
    rescue StandardError
      'N'
    end

  def rl_getc(_stream)
    while @kbhit.Call.zero?
      # If there is no input, yield the processor for other threads
      sleep(@_keyboard_input_timeout)
    end

    c = @getch.Call
    alt = (@GetKeyState.call(VK_LMENU) & 0x80) != 0

    if c.zero? || c == 0xE0
      while @kbhit.Call.zero?
        # If there is no input, yield the processor for other threads
        sleep(@_keyboard_input_timeout)
      end

      r = c.chr + @getch.Call.chr
    else
      r = c.chr
    end

    r.prepend("\e") if alt
    r
  end

  def rl_gather_tyi
    chars_avail = @kbhit.Call
    return 0 if chars_avail <= 0

    k = send(@rl_getc_function, @rl_instream)
    rl_stuff_char(k)
    1
  end
end
