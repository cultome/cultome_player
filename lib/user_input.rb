require 'readline'

# TODO
#  - Implementar pruebas para ff y fb
#  - Implementar prurbas para los nuevos caracteres del path
class String
	def blank?
		self.nil? || self.empty?
	end
end

module UserInput
	COMMANDS = {
		"play" => {help: "Create and inmediatly plays playlists", params_format: "(<number>|<criteria>|<object>|<literal>)*"},
		"enqueue" => {help: "Append the created playlist to the current playlist", params_format: "(<number>|<criteria>|<object>|<literal>)*"},
		"search" => {help: "Find inside library for song with the given criteria.", params_format: "(<criteria>|<object>|<literal>)*"},
		"show" => {help: "Display information about status, objects and library.", params_format: "<object>"},
		"pause" => {help: "Pause playback.", params_format: ""},
		"stop" => {help: "Stops playback.", params_format: ""},
		"next" => {help: "Play the next song in the queue.", params_format: "<number>"},
		"prev" => {help: "Play the previous song from the history.", params_format: ""},
		"connect" => {help: "Add files to the library.", params_format: "<path> => <literal>"},
		"disconnect" => {help: "Remove filesfrom the library.", params_format: "<literal>"},
		"quit" => {help: "Exit the player.", params_format: ""},
		"ff" => {help: "Fast forward 5 sec.", params_format: ""},
		"fb" => {help: "Fast backward 5 sec.", params_format: ""},
		"shuffle" => {help: "Check and change the status of shuffle.", params_format: "<number>|<literal>"},
		"repeat" => {help: "Repeat the current song", params_format: ""},
		"kill" => {help: "Delete from disk the current song", params_format: ""},
		"help" => {help: "This help.", params_format: "<literal>"},
	}

	ALIAS = {
		"exit" => "quit",
	}

	VALID_IN_CMD = COMMANDS.keys.join('|') + '|' + ALIAS.keys.join('|')

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
		raise "Invalid command. Try typing 'help' for information" if input !~ /\A(#{VALID_IN_CMD})[\s]*(.*)?\Z/

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

		unless ALIAS[cmd].nil?
			cmd = ALIAS[cmd]
		end

		{command: cmd, params: pretty_params}
	end

	def get_confirmation(msg)
		display(msg)
		display("y/N: ", true)
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

