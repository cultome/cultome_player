
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

        # The number of retries that this player try to connect with external player during launch. Every try wait 0.5 seconds before do another.
        EXTERNAL_LAUNCH_MAX_RETRIES = 6

        # Once the external player is running you can open a socket connection between this player and the external player.
        #
        # @param host [String] The hostname or ip of the machine running the external player.
        # @param port [Integer] The port number where the external player is listening for socket connections.
        def connect_external_music_player(host, port)
            raise 'One external player is already connected' if @socket

            begin
                attach_to_socket(host, port, :external_player_data_in)
                @connected = true
            rescue Exception => e
                kill_external_music_player unless @external_player_pid.blank?
            end
        end

        # Check the connection state of this player.
        #
        # @return [Boolean] true is this player is connected with an external player, false otherwise.
        def external_player_connected?
            @connected.blank?
        end

        # Run a user-defined command to initiate the external player. ALso record the process id in case the user wants to kill the process.
        #
        # @return [Integer] The process id captured if the external player was successfully launched.
        def launch_external_music_player
            retries = 1
            @external_player_pid = last_java_process = `ps -A | grep java`.each_line.map{|l| l =~ /\A([\s\d]+)/; $1.to_i }.max

            Thread.new do
                sleep(1.0)
                launch_external_music_player_command
            end

            begin
                # espera para crear el proceso java
                sleep(0.5)
                @external_player_pid = `ps -A | grep java`.each_line.map{|l| l =~ /\A([\s\d]+)/; $1.to_i }.max
                retries += 1
            end while retries < EXTERNAL_LAUNCH_MAX_RETRIES && last_java_process == @external_player_pid

            # espera para levantar el server
            sleep(1)

            raise 'External music player not launched!' if last_java_process == @external_player_pid

            return @external_player_pid
        end

        # Execute a kill in the process id captured by #launch_external_music_player. If no pid was captured an exception is arised.
        #
        # @return [Boolean] true if the process was killed successfuly, false otherwise.
        def kill_external_music_player
            raise 'There is no external player registered or and error ocurr when registering' unless @external_player_pid
            system("kill -9 #{@external_player_pid}")
            return $?.success?
        end

        # Callback method fired when information comes in the socket from the external player.
        #
        # @param data [String] The mesage received from the external player.
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

        # Send a play command throught the socket to the external player.
        #
        # @param external_file_system_path [String] The path to the music file to be played.
	    def play_in_external_player(external_file_system_path)
            write_to_socket("play", external_file_system_path) unless @socket.nil?
        end

        # Send a seek command throught the socket to the external player.
        #
        # @param next_pos [Integer] The position to which jump in the current playback
        def seek_in_external_player(next_pos)
            write_to_socket("seek", next_pos) unless @socket.nil?
        end

        # Send a pause command throught the socket to the external player.
		def pause_in_external_player
            write_to_socket("pause") unless @socket.nil?
        end

        # Send a resume command throught the socket to the external player.
        def resume_in_external_player
            write_to_socket("resume") unless @socket.nil?
        end

        # Send a stop command throught the socket to the external player.
		def stop_in_external_player
            write_to_socket("close") unless @socket.nil?
        end

        private

        # A user-defined command to launch the external player.
        #
        # @return [String] A command to launch external player
        def launch_external_music_player_command
            system(environment[:ext_player_launch_cmd])
        end
    end
end
