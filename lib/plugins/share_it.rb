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
			usage = <<HELP
There are two steps to be done to share a file with another computer across the internet.
The simple explanation is an example, so I'll tell you a history of two friends who enjoy listening music together, in two different places of earth, and are sharing their legally-acquaired music collection.

	1.  The server or friend-who-receive-the-file, named Mustafa, types:
		* receive /home/mustafa/received_songs MySecretPa55
	2.  Mustafa sends the secret token (MySecretPa55) and his IP (223.12.1.222) to his friend Jonh through chat or email or skype or whatever they are using.
	3.  Then Jonh plays the song he like to share with Mustafa and when is playing he types:
		* share 223.12.1.222 MySecretPa55
	4.  If all goes right and is done fast, the transfer must begin inmediatly and Mustafa receive the song.

Why fast? Well for security purposes Mustafa will listen for connection for a brief time, so this must be almost simultaneously in both sides, BUT ALWAYS the server must be listenening before the client tries to connect.

HELP
			{
				:share => {
					help: "Send the current song to someone else through the internet.",
				   	params_format: "<literal|ip> <literal|number>",
					usage: usage
				},
				:receive => {
					help: "Start listening for a music transfer connection.",
				   	params_format: "<path|object> <literal|number>",
					usage: usage
				},
			}
		end

		def share(params=[])
			return nil if params.size != 2
			return nil if params[0][:type] !~ /literal|ip/
			return nil if params[1][:type] !~ /literal|number/

			server = params[0][:value]
			token = params[1][:value]
			song_path = @cultome.song.path

			display(c4("You are transfering #{c14(@cultome.song)}") + c4(" to #{c14(server)}..."))

			client = ShareThis::Client.new
			success = client.send_to(server, token, song_path)
			if success
				display c4("The transfer was successful!")
			else
				display c2("There was an error with the transfer =S")
				if ENV['environment'] == 'dev'
					display c2("ERROR (#{client.error_code}): #{client.message}")
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

			display c4("You are waiting for connections...")

			server = ShareThis::Server.new
			success = server.wait_for_connection(token, save_dir)

			if success
				display c4("The transfer was successful!")
			else
				display c2("There was an error with the transfer =S")
				if ENV['environment'] == 'dev'
					display c2("ERROR (#{server.error_code}): #{server.message}")
				end
			end

			return success
		end
	end
end
