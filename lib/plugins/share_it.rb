require 'cultome/plugin'
require 'cultome/persistence'
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
				:share => {help: "Send the current song to someone else through the internet.", params_format: "<literal|ip> <literal|number>"},
				:receive => {help: "Start listening for a music transfer connection.", params_format: "<path|object> <literal|number>"},
			}
		end

		def share(params=[])
			return nil if params.size != 2
			return nil if params[0][:type] !~ /literal|ip/
			return nil if params[1][:type] !~ /literal|number/

			server = params[0][:value]
			token = params[1][:value]
			song_path = @cultome.song.path

			display("You are transfering #{@cultome.song} to #{server}...")

			client = ShareThis::Client.new
			success = client.send_to(server, token, song_path)
			if success
				display("The transfer was successful!")
			else
				display("There was an error with the transfer =S")
				if ENV['environment'] == 'dev'
					display("ERROR (#{client.error_code}): #{client.message}")
				end
			end

			return success
		end

		def receive(params=[])
			return nil if params.size != 2
			return nil if params[0][:type] !~ /path|object/
			return nil if params[1][:type] !~ /literal|number/

			if params[0][:type] == :path
				save_dir = params[0][:value]
			elsif params[0][:type] == :object
				drive = Drive.find_by_name(params[0][:value])
				return nil if drive.nil?
				save_dir = drive.path
			end

			token = params[1][:value]

			display("You are waiting for connections...")

			server = ShareThis::Server.new
			success = server.wait_for_connection(token, save_dir)

			if success
				display("The transfer was successful!")
			else
				display("There was an error with the transfer =S")
				if ENV['environment'] == 'dev'
					display("ERROR (#{server.error_code}): #{server.message}")
				end
			end

			return success
		end
	end
end
