require 'cultome/plugin'
require 'share_this/client'
require 'share_this/server'

module Plugin
	class ShareIt < PluginBase
		# Register the commands: share
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{
				:share => {help: "Send the current song to someone else through the internet.", params_format: "<literal> <literal|number>"},
				:receive => {help: "Start listening for a music transfer connection.", params_format: "<path> <literal|number>"},
			}
		end

		def share(params=[])
			return nil if params.size != 2
			return nil if params[0][:type] != :literal
			return nil if params[1][:type] != :literal && params[1][:type] != :number

			server_ip = params[0][:value]
			token = params[1][:value]
			song_path = @cultome.song.path

			display("You are transfering #{@cultome.song} to #{server_ip}...")

			success = ShareThis::Client.new.send_to(server_ip, token, song_path)
			if success
				display("The transfer was successful!")
			else
				display("There was an error with the transfer =S")
			end
		end

		def receive(params=[])
			return nil if params.size != 2
			return nil if params[0][:type] != :path
			return nil if params[1][:type] != :literal && params[1][:type] != :number

			save_dir = params[0][:value]
			token = params[1][:value]

			display("You are waiting for connections...")

			success = ShareThis::Server.new.wait_for_connection(token, save_dir)

			if success
				display("The transfer was successful!")
			else
				display("There was an error with the transfer =S")
			end
		end
	end
end
