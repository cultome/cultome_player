require 'shellwords'

module Plugins
	module CopyTo

		# Register the command: copy
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def self.get_command_registry
			{
				copy: {
					help: "Copy a playlist to some filesystem folder", 
					params_format: "<object> => <path>",
					usage: <<HELP
Copy a set of selected songs to a folder in the filesystem. The selected song set is the list holded by the <object> and the <path> is an absolute path in the filesystem, wrapped by " or ' if the path contains spaces.

The song set can be reviewed with the command
	* show <object>
For example
	* show @playlist
	* show @history
	* show @search

A common usages would be as follow:
	* copy @playlist => /mnt/mypod/music
	* copy @history => "/home/other/my music"

HELP
			}}
		end

		# Copy an object, that represent a list of songs, into one folder of the filesystem
		#
		# @param params [List<Hash>] With parsed player's object information and one path.
		def copy(params=[])
			raise CultomePlayerException.new(:no_active_playback, take_action: false) if cultome.song.nil?

			return nil if params.size != 2
			return nil unless params.one?{|a| a[:type] == :object }
			return nil unless params.one?{|a| a[:type] == :path }

			to_path = CopyTo.validate_path(params.find{|a| a[:type] == :path }[:value])
			return nil if to_path.nil?

			files = CopyTo.get_file_list(cultome, params.find{|a| a[:type] == :object }[:value])
			return nil if files.nil?

			return CopyTo.copy_files(cultome, files, to_path)
		end

		# Validate that the destination is an existing directory and we can write there.
		#
		# @param path [String] the path to a directory in the filesystem
		# @return [String, nil] return nil if the path is not valid. The path otherwise.
		def self.validate_path(path)
			File.exist?(path) && File.directory?(path) && File.writable?(path) ? path : nil
		end

		# Detect the object type and create a list of file paths.
		#
		# @param object [String] the name of the player's object.
		# @return [List<String>, nil] The files path list or nil if problem.
		def self.get_file_list(cultome, object)
			list = cultome.instance_variable_get("@#{object}")
			return [list.path] if list.class == Cultome::Song
			return nil if list.empty?


			if list[0].class == Cultome::Song
				return list.collect{|s| s.path }
			elsif list[0].class == Cultome::Artist
				artists_ids = list.collect{|a| a.id }
				songs = Cultome::Song.joins(:artists).where('artists.id in (?)', artists_ids).to_s
				return songs.collect{|s| s.path }
			elsif list[0].class == Cultome::Album
				albums_ids = list.collect{|a| a.id }
				songs = Cultome::Song.joins(:albums).where('albums.id in (?)', albums_ids).to_s
				return songs.collect{|s| s.path }
			else
				# podrian ser los similares
				return nil
			end
		end

		# Copy the file to the directory
		#
		# @param files [List<String>] The absolute paths to files
		# @param to_path[String] The path to the destination dir.
		def self.copy_files(cultome, files, to_path)
			display(c4("Copying #{c14(files.size.to_s)}") + c4(" files to #{c14(to_path)}..."))

			dir_path = Shellwords.escape(to_path)
			files.each do |f|
				display(c14("  #{f}..."))
				file_path = Shellwords.escape(f)

				system("cp #{file_path} #{dir_path}")
			end
		end
	end
end
