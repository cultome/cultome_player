# TODO
#  - Implementar pruebas para ff y fb
#  - Implementar prurbas para los nuevos caracteres del path
class String
  def blank?
    self.nil? || self.empty?
  end
end

module UserInput

  COMMANDS = %w{play search show pause stop next prev connect quit ff fb}
  ALIAS = %w{p s n}

  VALID_IN_CMD = COMMANDS.join('|') + '|' + ALIAS.join('|')

  VALID_CRITERIA_PREFIX = "[abs]"
  BUBBLE_WORD = %w{=>}

  def parse(input)
    prev_cmd = nil
    cmds = input.split('|').collect{|cmd|
      new_cmd = parse_command(cmd.strip)
      if prev_cmd.nil?
        prev_cmd = new_cmd
      else
        new_cmd[:params] << {type: :command, value: prev_cmd}
        prev_cmd[:piped] = true
        prev_cmd = new_cmd
      end
    }.compact

    cmds.delete_if{|c| c[:piped] }
# puts cmds.inspect
    cmds # ver que hacer si hay nils
  end

  def parse_command(input)
    return nil if input !~ /\A(#{VALID_IN_CMD})[\s]*(.*)?\Z/

    cmd = $1
    # params = $2.split(' ').collect{|s| if s.blank? then nil else s end }

    m = nil
    params = $2.split(' ').collect do |t|
      if t.blank?
        nil
      elsif m.nil?
        if t.index('"')
          m = t.gsub('"', '')
          nil
        else 
          t 
        end
      else
        m = m + ' ' + t.gsub('"', '')
        if t.index('"')
          temp = m
          m = nil
          temp
        else
          nil
        end
      end
    end

    pretty_params = parse_params(params.compact)

    # puts "CMD: #{cmd}\tPARAMS: #{pretty_params.inspect}"

    {command: cmd, params: pretty_params}
  end

  private

  def parse_params(params)
    params.collect{|param|
      case param
        when /\A[0-9]+\Z/ then {value: param, type: param.to_i > 0 ? :number : :unknown}
        when /\A([a-zA-Z]:[\/\\]|\/)(.+?)+\Z/ then {value: param.gsub(/(\/|\\)\Z/, ''), type: :path}
        when /\A(#{VALID_CRITERIA_PREFIX}):([\w ]+)\Z/ then {criteria: $1.to_sym, value: $2, type: :criteria}
        when /\A@([\w]+)\Z/ then {value: $1.to_sym, type: :object}
        when /\A[\w\d ]+\Z/ then {value: param, type: :literal}
        when /\A#{BUBBLE_WORD.join('|')}\Z/ then nil
        else {value: param, type: :unknown}
      end
    }.compact
  end
end