
module CultomePlayer
    module ExternalPlayer

        # The known states of the underlying music player.
        EXTERNAL_PLAYER_STATES = {
            -1 =>:UNKNOWN, 
            0 => :OPENING, 
            1 => :OPENED, 
            2 => :PLAYING, 
            3 => :STOPPED, 
            4 => :PAUSED, 
            5 => :RESUMED, 
            6 => :SEEKING, 
            7 => :SEEKED, 
            8 => :EOM, 
            9 => :PAN,
            10 =>:GAIN
        }

        def connect_external_music_player(host, port)
            raise 'One external player is already connected' if @socket

            attach_to_socket(host, port, :external_player_data_in)

            @connected = true
        end

        def external_player_connected?
            @connected
        end

        def launch_external_music_player
            last_java_process = 0
            Thread.new do
                last_java_process = `ps -A | grep java`.each_line.map{|l| l =~ /\A([\s\d]+)/; $1.to_i }.max

                launch_external_music_player_command
            end
            sleep(1)
            this_process = `ps -A | grep java`.each_line.map{|l| l =~ /\A([\s\d]+)/; $1.to_i }.max

            raise 'External music player not launched!' if last_java_process == this_process

            return @external_player_pid = this_process
        end

        def kill_external_music_player
            raise 'There is no external player registered or and error ocurr when registering' unless @external_player_pid
            system("kill -9 #{@external_player_pid}")
            return $?.success?
        end

        def external_player_data_in(data)
            split = data.split(SocketAdapter::PARAM_TERMINATOR_SEQ)

            case split[0]
            when 'progress'
                player.song_status = {
                    seconds: split[1].to_i,
                    bytes: split[2].to_i,
                    frame_size: split[3].to_i
                }

            when 'stateUpdated'
                old_state = player.state
                player.state = EXTERNAL_PLAYER_STATES[split[1].to_i]
                emit_event(:player_state_updated, old_state, player.state) if old_state != player.state

            when 'error'
                player.state = EXTERNAL_PLAYER_STATES[3] # STOPPED
                emit_event(:playback_fail, split[1])

            end
        end

	    def play_in_external_player(external_file_system_path)
            write_to_socket("play", external_file_system_path) unless @socket.nil?
        end
		
        def seek_in_external_player(next_pos)
            write_to_socket("seek", next_pos) unless @socket.nil?
        end

		def pause_in_external_player
            write_to_socket("pause") unless @socket.nil?
        end

        def resume_in_external_player
            write_to_socket("resume") unless @socket.nil?
        end

		def stop_in_external_player
            write_to_socket("close") unless @socket.nil?
        end

        private

        def launch_external_music_player_command
            system(environment[:ext_player_launch_cmd])
        end
    end
end
