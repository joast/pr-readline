# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Lint/MissingCopEnableDirective
# rubocop:disable Metrics/ClassLength
# rubocop:disable Metrics/MethodLength

require 'minitest/autorun'
require 'readline'

class TestReadline < Minitest::Test # :nodoc:
  def setup
    @proc = proc { |s| %w[alpha beta].grep(/^#{Regexp.escape(s)}/) }
  end

  def test_version
    assert_equal('5.2', Readline::VERSION)
  end

  def test_readline_basic
    assert_respond_to(Readline, :readline)
  end

  def test_readline_with_default_parameters_does_not_error
    thread = Thread.new { Readline.readline }
    sleep 0.1
    assert thread.alive?
  ensure
    thread.kill
  end

  def test_input_basic
    assert_respond_to(Readline, :input=)
  end

  def test_input
    Readline.input = $stdin
    assert_equal $stdin, PrReadline.rl_instream
  end

  def test_output_basic
    assert_respond_to(Readline, :output=)
  end

  def test_output
    Readline.output = $stdout
    assert_equal $stdout, PrReadline.rl_outstream
  end

  def test_completion_proc_get_basic
    assert_respond_to(Readline, :completion_proc)
  end

  def test_completion_proc_set_basic
    assert_respond_to(Readline, :completion_proc=)
  end

  def test_completion_proc
    Readline.completion_proc = @proc
    assert_equal @proc, Readline.completion_proc
  end

  def test_completion_case_fold_get_basic
    assert_respond_to(Readline, :completion_case_fold)
  end

  def test_completion_case_fold_default
    assert_equal(false, Readline.completion_case_fold) # default
  end

  def test_completion_case_fold_set_basic
    assert_respond_to(Readline, :completion_case_fold=)
  end

  def test_completion_case_fold_changed
    Readline.completion_case_fold = false
    refute Readline.completion_case_fold
  end

  def test_completion_proc_expected_errors
    assert_raises(ArgumentError) { Readline.completion_proc = 1 }
    assert_raises(ArgumentError) { Readline.completion_proc = 'a' }
  end

  def test_vi_editing_mode_basic
    assert_respond_to(Readline, :vi_editing_mode)
  end

  def test_vi_editing_mode_query_basic
    assert_respond_to(Readline, :vi_editing_mode?)

    Readline.emacs_editing_mode
    refute(Readline.vi_editing_mode?)
  end

  def test_emacs_editing_mode_basic
    assert_respond_to(Readline, :emacs_editing_mode)
  end

  def test_emacs_editing_mode_query_basic
    assert_respond_to(Readline, :emacs_editing_mode?)

    Readline.emacs_editing_mode
    assert(Readline.emacs_editing_mode?)
  end

  def test_completion_append_character_get_basic
    assert_respond_to(Readline, :completion_append_character)
  end

  def test_completion_append_character_get
    assert_equal(' ', Readline.completion_append_character) # default
  end

  def test_completion_append_character_set_basic
    assert_respond_to(Readline, :completion_append_character=)
  end

  def test_completion_append_character_set
    assert_equal ' ', Readline.completion_append_character
  end

  def test_completion_append_character
    orig_char = Readline.completion_append_character
    begin
      [
        %w[x x],
        %w[xyx x],
        [' ', ' '],
        %W[\t \t],
        ['', nil]
      ].each do |data, expected|
        Readline.completion_append_character = data
        if expected.nil?
          assert_nil(Readline.completion_append_character,
                     "failed case: [#{data.inspect}, #{expected.inspect}]")
        else
          assert_equal(expected, Readline.completion_append_character,
                       "failed case: [#{data.inspect}, #{expected.inspect}]")
        end
      end
    ensure
      Readline.completion_append_character = orig_char
    end
  end

  def test_basic_word_break_characters_get_basic
    assert_respond_to(Readline, :basic_word_break_characters)
  end

  def test_basic_word_break_characters_get
    assert_equal(" \t\n\"\\'`@$><=|&{(", Readline.basic_word_break_characters)
  end

  def test_basic_word_break_characters_set_basic
    assert_respond_to(Readline, :basic_word_break_characters=)
  end

  def test_basic_word_break_characters_set
    chars = " \t\n\"\\'`@$><=|&{("
    Readline.basic_word_break_characters = chars
    assert_equal chars, Readline.basic_word_break_characters
  end

  def test_basic_quote_characters_get_basic
    assert_respond_to(Readline, :basic_quote_characters)
  end

  def test_basic_quote_characters_get
    assert_equal "\"'", Readline.basic_quote_characters
  end

  def test_basic_quote_characters_set_basic
    assert_respond_to(Readline, :basic_quote_characters=)
  end

  def test_basic_quote_characters_set
    chars = "\"'"
    Readline.basic_quote_characters = chars
    assert_equal chars, Readline.basic_quote_characters
  end

  def test_some_character_methods
    expecteds = [' ', " .,|\t", '']
    %i[
      basic_word_break_characters
      completer_word_break_characters
      basic_quote_characters
      completer_quote_characters
      filename_quote_characters
    ].each do |method|
      saved = Readline.send(method)
      expecteds.each do |e|
        Readline.send("#{method}=".to_sym, e)
        assert_equal(e, Readline.send(method),
                     "failed case #{e.inspect} for method #{method}")
      ensure
        Readline.send("#{method}=".to_sym, saved) if saved
      end
    end
  end

  def test_attempted_comp_func_returns_nil_when_no_completion_proc_set
    assert_nil Readline.readline_attempted_completion_function('12', 0, 1)
  end

  def test_attempted_comp_func_case_folding
    Readline.completion_proc = proc do |word|
      %w[123456 123abc abc123].grep(/^#{word}/i)
    end

    Readline.completion_case_fold = true

    assert_equal(['123', '123456', '123abc', nil],
                 Readline.readline_attempted_completion_function('123', 0, 3))

    assert_equal(['123abc', nil, nil],
                 Readline.readline_attempted_completion_function('123A', 0, 3))
  ensure
    Readline.completion_case_fold = false
    Readline.module_eval { @completion_proc = nil }
  end

  def test_attempted_comp_func_removes_replacement_from_possible_matches
    Readline.completion_proc = proc do |word|
      %w[123456 123abc abc123].grep(/^#{word}/)
    end

    assert_equal(['123', '123456', '123abc', nil],
                 Readline.readline_attempted_completion_function('12', 0, 1))

    assert_equal(['123', '123456', '123abc', nil],
                 Readline.readline_attempted_completion_function('123', 0, 2))

    assert_equal(['123456', nil, nil],
                 Readline.readline_attempted_completion_function('1234', 0, 3))
  ensure
    Readline.module_eval { @completion_proc = nil }
  end

  def teardown
    @proc = nil
  end
end
