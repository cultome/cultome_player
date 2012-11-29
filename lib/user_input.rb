
class String
  def blank?
    self.nil? || self.empty?
  end
end

module UserInput

  COMMANDS = %w{play search show pause stop next prev}
  ALIAS = %w{p s n}

  VALID_IN_CMD = COMMANDS.join('|') + '|' + ALIAS.join('|')

  VALID_CRITERIA_PREFIX = "[abs]"

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
    params = $2.split(' ').collect{|s| if s.blank? then nil else s end }
    pretty_params = parse_params(params)

    # puts "CMD: #{cmd}\tPARAMS: #{pretty_params.inspect}"

    {command: cmd, params: pretty_params}
  end

  private

  def parse_params(params)
    params.collect{|param|
      case param
        when /\A[\d]+\Z/ then {value: param, type: :number}
        when /\A(#{VALID_CRITERIA_PREFIX}):([\w]+)\Z/ then {criteria: $1.to_sym, value: $2, type: :criteria}
        when /\A@([\w]+)\Z/ then {value: $1, type: :object}
        when /\A[\w\d]+\Z/ then {value: param, type: :literal}
        else {value: param, type: :unknown}
      end
    }
  end
end