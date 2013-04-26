require 'cultome/plugin'

module Plugin
	class CopyTo < PluginBase

		# Register the command: copy
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{copy: {help: "Copy a playlist to some filesystem folder", params_format: "<object> => <path>"}}
		end

		# Copy an object, that represent a list of songs, into one folder of the filesystem
		#
		# @param params [List<Hash>] With parsed player's object information and one path.
		def copy(params=[])
			return nil if params.size != 2
			return nil unless params.one?{|a| a[:type] == :object }
			return nil unless params.one?{|a| a[:type] == :path }

			to_path = validate_path(params.find{|a| a[:type] == :path }[:value])
			return nil if to_path.nil?

			files = get_file_list(params.find{|a| a[:type] == :object }[:value])
			return nil if files.nil?

			return copy_files(files, to_path)
		end

		private

		# Validate that the destination is an existing directory and we can write there.
		#
		# @param path [String] the path to a directory in the filesystem
		# @return [String, nil] return nil if the path is not valid. The path otherwise.
		def validate_path(path)
			File.exist?(path) && File.directory?(path) && File.writable?(path) ? path : nil
		end

		# Detect the object type and create a list of file paths.
		#
		# @param object [String] the name of the player's object.
		# @return [List<String>, nil] The files path list or nil if problem.
		def get_file_list(object)
			list = @p.instance_variable_get("@#{object}")
			return nil if list.empty?


			if list[0].class == Song
				return list.collect{|s| s.path }
			elsif list[0].class == Artist
				artists_ids = list.collect{|a| a.id }
				songs = Song.joins(:artists).where('artists.id in (?)', artists_ids).to_s
				return songs.collect{|s| s.path }
			elsif list[0].class == Album
				albums_ids = list.collect{|a| a.id }
				songs = Song.joins(:albums).where('albums.id in (?)', albums_ids).to_s
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
		def copy_files(files, to_path)
			display("Copying #{files.size} files to #{to_path}...")

			dir_path = Shellwords.escape(to_path)
			files.each do |f|
				display("  #{f}...")
				file_path = Shellwords.escape(f)

				system("cp #{file_path} #{dir_path}")
			end
		end
	end
end