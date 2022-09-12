# encoding: US-ASCII
#
# readline.rb -- GNU Readline module
# Copyright (C) 1997-2001  Shugo Maeda
#
# Ruby translation by Park Heesob phasis@gmail.com
# Renamed from RbReadline to PrReadline by Rick Ohnemus rick_ohnemus@acm.org

module Readline
  require_relative 'prreadline'
  include PrReadline

  @completion_proc = nil
  @completion_case_fold = false

  # Begins an interactive terminal process using +prompt+ as the command
  # prompt that users see when they type commands. The method returns the
  # line entered whenever a carriage return is encountered.
  #
  # If an +add_history+ argument is provided, commands entered by users are
  # stored in a history buffer that can be recalled for later use.
  #
  # Note that this method depends on $stdin and $stdout both being open.
  # Because this is meant as an interactive console interface, they should
  # generally not be redirected.
  #
  # If you would like to add non-visible characters to the the prompt (for
  # example to add colors) you must prepend the character \001 (^A) before
  # each sequence of non-visible characters and add the character \002 (^B)
  # after, otherwise line wrapping may not work properly.
  #
  # Example:
  #
  #    loop{ Readline.readline('> ') }
  #
  def readline(prompt = "", add_history = nil)
    if $stdin.closed?
      raise IOError, "stdin closed"
    end

    PrReadline.rl_instream = $stdin
    PrReadline.rl_outstream = $stdout

    begin
      buff = PrReadline.readline(prompt)
    rescue Exception => e
      buff = nil
      PrReadline.rl_cleanup_after_signal()
      PrReadline.rl_deprep_terminal()
      raise e
    end

    if add_history && buff
      PrReadline.add_history(buff)
    end

    return buff ? buff.dup : nil
  end

  # Sets the input stream (an IO object) for readline interaction. The
  # default is <tt>$stdin</tt>.
  #
  def self.input=(input)
    PrReadline.rl_instream = input
  end

  # Sets the output stream (an IO object) for readline interaction. The
  # default is <tt>$stdout</tt>.
  #
  def self.output=(output)
    PrReadline.rl_outstream = output
  end

  # Returns current line buffer
  #
  def self.line_buffer
    PrReadline.rl_line_buffer
  end

  # Sets the auto-completion procedure (i.e. tab auto-complete).
  #
  # The +proc+ argument is typically a Proc object. It must respond to
  # <tt>.call</tt>, take a single String argument and return an Array of
  # candidates for completion.
  #
  # Example:
  #
  #    list = ['search', 'next', 'clear']
  #    Readline.completion_proc = proc{ |s| list.grep( /^#{Regexp.escape(s)}/) }
  #
  def self.completion_proc=(proc)
    unless proc.respond_to? :call
      raise ArgumentError,"argument must respond to `call'"
    end
    @completion_proc = proc
  end

  # Returns the current auto-completion procedure.
  #
  def self.completion_proc()
    @completion_proc
  end

  # Sets whether or not the completion proc should ignore case sensitivity.
  # The default is false, i.e. completion procs are case sensitive.
  #
  def self.completion_case_fold=(bool)
    @completion_case_fold = bool
  end

  # Returns whether or not the completion proc is case sensitive. The
  # default is false, i.e. completion procs are case sensitive.
  #
  def self.completion_case_fold()
    @completion_case_fold
  end

  # Returns nil if no matches are found or an array of strings:
  #
  #   [0] is the replacement for text
  #   [1..n] the possible matches
  #   [n+1] nil
  #
  # The possible matches should not include [0].
  #
  # If this method sets PrReadline.rl_attempted_completion_over to true,
  # then the default completion function will not be called when this
  # function returns nil.
  def self.readline_attempted_completion_function(text,start,_end)
    proc = @completion_proc
    return nil if proc.nil?

    PrReadline.rl_attempted_completion_over = true

    case_fold = @completion_case_fold
    ary = proc.call(text)
    if ary.class != Array
      ary = Array(ary)
    else
      ary.compact!
    end

    matches = ary.length
    return nil if (matches == 0)
    result = Array.new(matches+2)
    for i in 0 ... matches
      result[i+1] = ary[i].dup
    end
    result[matches+1] = nil

    if(matches==1)
      result[0] = result[1].dup
      result[1] = nil
    else
      i = 1
      low = 100000

      while (i < matches)
        if (case_fold)
          si = 0
          while ((c1 = result[i][si,1].downcase) &&
                 (c2 = result[i + 1][si,1].downcase))
            break if (c1 != c2)
            si += 1
          end
        else
          si = 0
          while ((c1 = result[i][si,1]) &&
                 (c2 = result[i + 1][si,1]))
            break if (c1 != c2)
            si += 1
          end
        end
        if (low > si)
          low = si
        end
        i+=1
      end
      result[0] = result[1][0,low]
    end

    result
  end

  # Sets vi editing mode.
  #
  def self.vi_editing_mode()
    PrReadline.rl_vi_editing_mode(1,0)
    nil
  end

  # Tests if in vi editing mode.
  #
  def self.vi_editing_mode?
    PrReadline.rl_vi_editing_mode?
  end

  # Sets emacs editing mode
  #
  def self.emacs_editing_mode()
    PrReadline.rl_emacs_editing_mode(1,0)
    nil
  end

  # Test if in emacs editing mode.
  #
  def self.emacs_editing_mode?
    PrReadline.rl_emacs_editing_mode?
  end

  # Sets the character that is automatically appended after the
  # Readline.completion_proc method is called.
  #
  # If +char+ is nil or empty, then a null character is used.
  #
  def self.completion_append_character=(char)
    if char.nil?
      PrReadline.rl_completion_append_character = ?\0
    elsif char.length==0
      PrReadline.rl_completion_append_character = ?\0
    else
      PrReadline.rl_completion_append_character = char[0].chr
    end
  end

  # Returns the character that is automatically appended after the
  # Readline.completion_proc method is called.
  #
  def self.completion_append_character()
    if PrReadline.rl_completion_append_character == ?\0
      nil
    else
      PrReadline.rl_completion_append_character
    end
  end

  # Sets the character string that signal a break between words for the
  # completion proc.
  #
  def self.basic_word_break_characters=(str)
    PrReadline.rl_basic_word_break_characters = str.dup
  end

  # Returns the character string that signal a break between words for the
  # completion proc. The default is " \t\n\"\\'`@$><=|&{(".
  #
  def self.basic_word_break_characters()
    if PrReadline.rl_basic_word_break_characters.nil?
      nil
    else
      PrReadline.rl_basic_word_break_characters.dup
    end
  end

  # Sets the character string that signal the start or end of a word for
  # the completion proc.
  #
  def self.completer_word_break_characters=(str)
    PrReadline.rl_completer_word_break_characters = str.dup
  end

  # Returns the character string that signal the start or end of a word for
  # the completion proc.
  #
  def self.completer_word_break_characters()
    if PrReadline.rl_completer_word_break_characters.nil?
      nil
    else
      PrReadline.rl_completer_word_break_characters.dup
    end
  end

  # Sets the list of quote characters that can cause a word break.
  #
  def self.basic_quote_characters=(str)
    PrReadline.rl_basic_quote_characters = str.dup
  end

  # Returns the list of quote characters that can cause a word break.
  # The default is "'\"" (single and double quote characters).
  #
  def self.basic_quote_characters()
    if PrReadline.rl_basic_quote_characters.nil?
      nil
    else
      PrReadline.rl_basic_quote_characters.dup
    end
  end

  # Sets the list of characters that can be used to quote a substring of
  # the line, i.e. a group of characters within quotes.
  #
  def self.completer_quote_characters=(str)
    PrReadline.rl_completer_quote_characters = str.dup
  end

  # Returns the list of characters that can be used to quote a substring
  # of the line, i.e. a group of characters inside quotes.
  #
  def self.completer_quote_characters()
    if PrReadline.rl_completer_quote_characters.nil?
      nil
    else
      PrReadline.rl_completer_quote_characters.dup
    end
  end

  # Sets the character string of one or more characters that indicate quotes
  # for the filename completion of user input.
  #
  def self.filename_quote_characters=(str)
    PrReadline.rl_filename_quote_characters = str.dup
  end

  # Returns the character string used to indicate quotes for the filename
  # completion of user input.
  #
  def self.filename_quote_characters()
    if PrReadline.rl_filename_quote_characters.nil?
      nil
    else
      PrReadline.rl_filename_quote_characters.dup
    end
  end

  # Returns the current offset in the current input line.
  #
  def self.point()
    PrReadline.rl_point
  end

  # Temporarily disable warnings and call a block
  #
  def self.silence_warnings(&block)
    warn_level = $VERBOSE
    $VERBOSE = nil
    result = block.call
    $VERBOSE = warn_level
    result
  end

  # The History class encapsulates a history of all commands entered by
  # users at the prompt, providing an interface for inspection and retrieval
  # of all commands.
  class History
    extend Enumerable

    # The History class, stringified in all caps.
    #--
    # Why?
    #
    def self.to_s
      "HISTORY"
    end

    # Returns the command that was entered at the specified +index+
    # in the history buffer.
    #
    # Raises an IndexError if the entry is nil.
    #
    def self.[](index)
      if index < 0
        index += PrReadline.history_length
      end
      entry = PrReadline.history_get(PrReadline.history_base+index)
      if entry.nil?
        raise IndexError,"invalid index"
      end
      entry.line.dup
    end

    # Sets the command +str+ at the given index in the history buffer.
    #
    # You can only replace an existing entry. Attempting to create a new
    # entry will result in an IndexError.
    #
    def self.[]=(index,str)
      if index<0
        index += PrReadline.history_length
      end
      entry = PrReadline.replace_history_entry(index,str,nil)
      if entry.nil?
        raise IndexError,"invalid index"
      end
      str
    end

    # Synonym for Readline.add_history.
    #
    def self.<<(str)
      PrReadline.add_history(str)
    end

    # Pushes a list of +args+ onto the history buffer.
    #
    def self.push(*args)
      args.each do |str|
        PrReadline.add_history(str)
      end
    end

    # Internal function that removes the item at +index+ from the history
    # buffer, performing necessary duplication in the process.
    #--
    # TODO: mark private?
    #
    def self.rb_remove_history(index)
      entry = PrReadline.remove_history(index)
      if (entry)
        val = entry.line.dup
        entry = nil
        return val
      end
      nil
    end

    # Removes and returns the last element from the history buffer.
    #
    def self.pop()
      if PrReadline.history_length>0
        rb_remove_history(PrReadline.history_length-1)
      else
        nil
      end
    end

    # Removes and returns the first element from the history buffer.
    #
    def self.shift()
      if PrReadline.history_length>0
        rb_remove_history(0)
      else
        nil
      end
    end

    # Iterates over each entry in the history buffer.
    #
    def self.each()
      for i in 0 ... PrReadline.history_length
        entry = PrReadline.history_get(PrReadline.history_base + i)
        break if entry.nil?
        yield entry.line.dup
      end
      self
    end

    # Returns the length of the history buffer.
    #
    def self.length()
      PrReadline.history_length
    end

    # Synonym for Readline.length.
    #
    def self.size()
      PrReadline.history_length
    end

    # Returns a bolean value indicating whether or not the history buffer
    # is empty.
    #
    def self.empty?()
      PrReadline.history_length == 0
    end

    # Deletes an entry from the histoyr buffer at the specified +index+.
    #
    def self.delete_at(index)
      if index < 0
        i += PrReadline.history_length
      end
      if index < 0 || index > PrReadline.history_length - 1
        raise IndexError, "invalid index"
      end
      rb_remove_history(index)
    end

  end

  silence_warnings { HISTORY = History }

  # The Fcomp class provided to encapsulate typical filename completion
  # procedure. You will not typically use this directly, but will instead
  # use the Readline::FILENAME_COMPLETION_PROC.
  #
  class Fcomp
    def self.call(str)
      matches = PrReadline.rl_completion_matches(str, :rl_filename_completion_function)
      if (matches)
        result = []
        i = 0
        while(matches[i])
          result << matches[i].dup
          matches[i] = nil
          i += 1
        end
        matches = nil
        if (result.length >= 2)
          result.shift
        end
      else
        result = nil
      end
      return result
    end
  end

  silence_warnings { FILENAME_COMPLETION_PROC = Fcomp }

  # The Ucomp class provided to encapsulate typical filename completion
  # procedure. You will not typically use this directly, but will instead
  # use the Readline::USERNAME_COMPLETION_PROC.
  #
  # Note that this feature currently only works on Unix systems since it
  # ultimately uses the Etc module to iterate over a list of users.
  #
  class Ucomp
    def self.call(str)
      matches = PrReadline.rl_completion_matches(str, :rl_username_completion_function)
      if (matches)
        result = []
        i = 0
        while(matches[i])
          result << matches[i].dup
          matches[i] = nil
          i += 1
        end
        matches = nil
        if (result.length >= 2)
          result.shift
        end
      else
        result = nil
      end
      return result
    end
  end

  silence_warnings { USERNAME_COMPLETION_PROC = Ucomp }

  PrReadline.rl_readline_name = "Ruby"

  PrReadline.using_history()

  silence_warnings { VERSION = PrReadline.rl_library_version }

  module_function :readline

  PrReadline.rl_attempted_completion_function = :readline_attempted_completion_function

end
