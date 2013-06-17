require 'readline'

module CultomePlayer
    module UserInput

        VALID_CRITERIA_PREFIX = "[abt]"
        BUBBLE_WORD = %w{=>}

        # Read the user input. Provide funcitonality like history and limited autocomplete.
        #
        # @return [String] The user input.
        def get_command(msg, history=true)
            if os == :windows
                display msg
                return gets.chomp
            end
            # requiere del stty
            Readline::readline(c4(msg), history)
        end

        # Convert the user into a Hash full of ordered and clasified command
        # information.
        #
        # @param input [String] The user input.
        # @return [List<Hash>] The hashes contains the keys :command, :params. The latter is and array of hashes with the keys, dependending on the parameter type, :value, :type, :criteria.
        def parse(input)
            if input =~ /(["'].+?\|.+?["'])/
                # pipe dentro de comillas
                begin
                    piped = $1
                    escaped = piped.gsub('|', '__PIPE__')
                    input.gsub!(piped, escaped) =~ /(["'].+?\|.+?["'])/
                end while !$1.nil?

                    cmds = input.split('|').collect{|cmd|
                        parse_command(cmd.strip.gsub('__PIPE__', '|'))
                    }.compact
            else
                # pipe simple o no pipe
                cmds = input.split('|').collect{|cmd|
                    parse_command(cmd.strip)
                }.compact
            end

            cmds # ver que hacer si hay nils
        end


        # Display a prompt and read user input, return true if user input matches
        # known true values.
        #
        # @param msg [String] The prompt displayed to the user.
        # @return (see #is_true_value)
        def get_confirmation(msg)
            display c5(msg)
            is_true_value get_command("  [y/N]: ", false)
        end

        # Return true if value matches /Y|y|yes|1|si|s|ok/
        #
        # @param value [String] The value to be compared with regex
        # @return [Boolean] true if value matches /Y|y|yes|1|si|s|ok/, false otherwise.
        def is_true_value(value)
            value =~ /\A(Y|y|yes|1|si|s|ok|on|true)\Z/ ? true : false
        end

        # Create and return a valid commands regex.
        #
        # @return [String] An or-regex with the valid commands.
        def valid_command_regex
            @valid_comand_regex ||= Player.command_registry.join('|')
        end

        private

        # Validates and split the user input to process it easyly later.
        #
        # @param (see #parse)
        # @return [Hash] Contains the keys :command, :params. The latter is and array of hashes with the keys, dependending on the parameter type, :value, :type, :criteria.
        def parse_command(input)
            raise 'invalid command' if input !~ /\A(#{valid_command_regex})[\s]*(.*)?\Z/

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

            {command: cmd, params: pretty_params}
        end

        # Parse a parameter list.
        #
        # @param params [List<String>] A parameter values list.
        # @return [List<Hash>] Array of hashes with the keys, dependending on the parameter type, :value, :type, :criteria.
        def parse_params(params)
            params.collect{|param|
                case param
                when /\A[0-9]+\Z/ then {value: param.to_i, type: param.to_i > 0 ? :number : :unknown}
                when /\A([a-zA-Z]:[\/\\]|\/)(.+?)+\Z/ then {value: param.gsub(/(\/|\\)\Z/, ''), type: :path}
                when /\A(#{VALID_CRITERIA_PREFIX}):([\w ]+)\Z/ then {criteria: $1.to_sym, value: $2, type: :criteria}
                when /\A@([\w]+)\Z/ then {value: $1.to_sym, type: :object}
                when /\A[\d]{1,3}\.[\d]{1,3}\.[\d]{1,3}\.[\d]{1,3}\Z/ then {value: param, type: :ip}
                when /\A[\w\d ]+\Z/ then {value: param, type: :literal}
                when /\A#{BUBBLE_WORD.join('|')}\Z/ then nil
                else {value: param, type: :unknown}
                end
            }.compact
        end

    end
end
