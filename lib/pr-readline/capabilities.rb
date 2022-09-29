# encoding: US-ASCII
# warn_indent: true
# frozen_string_literal: true

# rubocop:disable Metrics/MethodLength

module PrReadline # :nodoc:
  def self.load_capabilities(type, func, dflt, verbose: false)
    File.open("#{__dir__}/../../data/#{type}_capabilities", 'rt') do |f|
      f.each do |line|
        line.strip!
        next if line.empty? || line[0] == '#'

        capname, iv, _desc = line.split(nil, 3)

        if func.nil?
          value = dflt
        else
          begin
            value = func.call(capname)
          rescue TerminfoError => e
            value = dflt
            warn "load_capabilities(#{type}): #{e}" if verbose
          end
        end

        instance_variable_set("@_rl_term_#{iv}", value)
      end
    end
  end
end

# rubocop:enable Metrics/MethodLength
