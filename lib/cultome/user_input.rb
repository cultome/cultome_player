require 'readline'

module Cultome::UserInput

	ALIAS = {
		exit: :quit,
	}

	VALID_CRITERIA_PREFIX = "[abt]"
	BUBBLE_WORD = %w{=>}

	def valid_alias
		if @valid_aliases.nil?
			@valid_aliases = ALIAS.keys.join('|')
		end

		@valid_aliases
	end

	def valid_command
		if @valid_commands.nil?
			@valid_comands = @command_registry.keys.join('|')
		end

		@valid_comands
	end

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
		raise "Invalid command. Try typing 'help' for information" if input !~ /\A(#{valid_command}|#{valid_alias})[\s]*(.*)?\Z/

		cmd = $1.to_sym
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

		unless ALIAS[cmd].nil?
			cmd = ALIAS[cmd]
		end

		{command: cmd, params: pretty_params}
	end

	def get_confirmation(msg)
		display(msg)
		display("  [y/N]: ", true)
		is_true_value gets.chomp
	end

	def is_true_value(value)
		value =~ /Y|y|yes|1|si|s|ok/
	end

	def get_command
		Readline::readline(@prompt, true)
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

