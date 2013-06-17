module CultomePlayer
    module Interactive

        def self.included(base)
            Player.command_registry << :quit
            Player.command_help_registry[:quit] = {
                help: "Exit the player.",
                params_format: "",
                usage: <<-HELP
Shutdown the player. In this moment is when the player save the plugin configurations of this session, for example, created aliases.

                HELP
            }
        end

        def begin_interactive(prompt=nil)
            @running = true

            player.current_prompt = prompt unless prompt.nil?

            display c4("Welcome to CulToMe Player v#{VERSION}")

            input = nil

            while(@running)
                prev_cmd = input unless input.blank?

                input = get_command(player.current_prompt, true)
                input = prev_cmd if input.blank? && !prev_cmd.blank?

                with_connection do
                    begin
                        return_value = execute input
                        display return_value.last if displayable?(return_value.last.to_s) 
                    rescue Exception => e
                        display c2(e.message)
                    end
                end
            end

            display c4("Bye!")
        end

        def quit(params=[])
            @running = false
            emit_event(:quitting)
        end

        private

        def displayable?(value)
            value =~ /\A([\d\s]+)?(#<.*>|[\d]+|\{.*\})\Z/ ? false : true
        end
    end
end
