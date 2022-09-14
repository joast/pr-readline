# encoding: US-ASCII
# warn_indent: true
# frozen_string_literal: true

module PrReadline # :nodoc:
  @encoding = case ENV.fetch('LANG', nil)
              when /\.UTF-8/
                'U'
              when /\.EUC/
                'E'
              when /\.SHIFT/
                'S'
              else
                'N'
              end

  module_function

  def rl_getc(stream)
    begin
      c = stream.read(1)
    rescue Errno::EINTR
      retry
    end

    c || EOF
  end

  def rl_gather_tyi
    result = select([@rl_instream], nil, nil, 0.1)
    return 0 if result.nil?

    k = send(@rl_getc_function, @rl_instream)
    rl_stuff_char(k)
    1
  end
end
