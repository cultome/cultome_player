require 'shellwords'

module CultomePlayer::Extras
    module CopyTo

        # Register the command copy.
        def self.included(base)
            CultomePlayer::Player.command_registry << :copy
            CultomePlayer::Player.command_help_registry[:copy] = {
                help: "Copy a playlist to some filesystem folder", 
                params_format: "<object> => <path>",
                usage: <<-HELP
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
            }
        end

        # Copy an object, that represent a list of songs, into one folder of the filesystem
        #
        # @param params [List<Hash>] With parsed player's object information and one path.
        def copy(params=[])
            raise 'no active playback' if current_song.nil?

            raise 'two parameters are required' if params.size != 2
            raise 'one object parameter are required' unless params.one?{|a| a[:type] == :object }
            raise 'one path parameter are required' unless params.one?{|a| a[:type] == :path }

            path = params.find{|a| a[:type] == :path }[:value]
            raise 'the path parameter is not a valid directory' unless valid_file_path?(path)

            files = file_list_from(params.find{|a| a[:type] == :object }[:value])
            raise 'the object hold reference to no songs' if files.nil?

            return copy_files(files, path)
        end

        private

        # Validate that the destination is an existing directory and we can write there.
        #
        # @param path [String] the path to a directory in the filesystem
        # @return [String, nil] return nil if the path is not valid. The path otherwise.
        def valid_file_path?(path)
            File.exist?(path) && File.directory?(path) && File.writable?(path)
        end

        # Detect the object type and create a list of file paths.
        #
        # @param object [String] the name of the player's object.
        # @return [List<String>, nil] The files path list or nil if problem.
        def file_list_from(object)
            list = player.instance_variable_get("@#{object}")
            return [list.path] if list.class == CultomePlayer::Model::Song
            return nil if list.empty?


            if list[0].class == CultomePlayer::Model::Song
                return list.collect{|s| s.path }
            elsif list[0].class == CultomePlayer::Model::Artist
                artists_ids = list.collect{|a| a.id }
                songs = CultomePlayer::Model::Song.joins(:artists).where('artists.id in (?)', artists_ids).to_s
                return songs.collect{|s| s.path }
            elsif list[0].class == CultomePlayer::Model::Album
                albums_ids = list.collect{|a| a.id }
                songs = CultomePlayer::Model::Song.joins(:albums).where('albums.id in (?)', albums_ids).to_s
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
