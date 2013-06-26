# encoding: utf-8
require 'cultome_player/player/help/basic_controls_help'
require 'mp3info'

module CultomePlayer::Player
    module BasicControls

        # Register all the command provided by this module to the player, which are: play, enqueue, search, pause, stop, next, prev, connect, disconnect, ff, fb, shuffle, repeat
        #
        # @param base [Class] The class where this module was included.
        def self.included(base)
            base.command_registry << :play
            base.command_registry << :enqueue
            base.command_registry << :search
            base.command_registry << :pause
            base.command_registry << :stop
            base.command_registry << :next
            base.command_registry << :prev
            base.command_registry << :connect
            base.command_registry << :disconnect
            base.command_registry << :ff
            base.command_registry << :fb
            base.command_registry << :shuffle
            base.command_registry << :repeat

            base.send :include, BasicControlsHelp
        end

        # Create and play a playlist with the results of parameters criterios.
        #
        # @param params [List<Hash>] The hashes contains the keys, dependending on the parameter type, :value, :type, :criteria.
        # @return (see #do_play)
        def play(params=[])
            pl = generate_playlist(params)
            # si se encolan
            unless pl.blank?
                player.playlist = player.focus = pl
                player.play_index = -1
                player.queue = []
                @songs_not_played_in_playlist = (0...current_playlist.size).to_a
            end

            #return nil if pl.blank? && !current_playlist.blank?

            player.history.push current_song unless current_song.nil?
            do_play

            return select_play_return_value(params)
        end

		# Add songs to the current playlist.
		#
		# @param (see #play)
		# @return [List<Song>] The new playlist.
		def enqueue(params=[])
			pl = generate_playlist(params)
			player.playlist = player.focus = current_playlist + pl 
			songs_not_played_in_playlist << current_playlist.size
            return current_playlist
		end

        # Search for songs in the connected drives.
        #
        # @param (see #play)
        # @return [List<Song>] The results of the search
        def search(params=[])
            return [] if params.blank?

            query = {
                or: [],
                and: []
            }

            params.each do |param|
                param_value = "%#{param[:value]}%"

                case param[:type]
                when :literal
                    query[:or] << {id: 1, condition: '(artists.name like ? or albums.name like ? or songs.name like ?)', value: [param_value] * 3}
                when :criteria
                    if param[:criteria] == :a then query[:and] << {id: 2, condition: 'artists.name like ?', value: param_value}
                    elsif param[:criteria] == :b then query[:and] << {id: 3, condition: 'albums.name like ?', value: param_value}
                    elsif param[:criteria] == :t then query[:and] << {id: 4, condition: 'songs.name like ?', value: param_value} end
                when :object
                    case param[:value]
                    when :artist then query[:and] << {id: 12, condition: 'artists.id = ?', value: player.artist.id}
                    when :album then query[:and] << {id: 13, condition: 'albums.id = ?', value: player.album.id}
                    end
                end
            end

            results = find_by_query(query).to_a

            raise "No results found!" if results.empty?

            return player.search_results = player.focus = results
        end

        # Select the next song to be played and plays it.
        #
        # @return (see #do_play)
        def next(params=[])
            if player.play_index + 1 < current_playlist.size
                player.history.push current_song unless current_song.nil?

                if player.shuffling?
                    # Para tener un mejor random hacemos qur toque 
                    # primero toda la playlist antes de repetir las rolas
                    if songs_not_played_in_playlist.empty?
                        @songs_not_played_in_playlist = (0...current_playlist.size).to_a
                    end

                    idx = songs_not_played_in_playlist.sample
                    songs_not_played_in_playlist.delete(idx)
                    player.queue.push current_playlist[idx]
                else
                    player.play_index += 1
                    player.queue.push current_playlist[player.play_index]
                end

                do_play
            else
                raise "No more songs in playlist!"
            end
        end

        # Get the latest song from history and plays it.
        #
        # @return (see #do_play)
        def prev(params=[])
            if player.history.blank?
                raise "There is no files in history"
            else
                player.queue.unshift player.history.pop
                player.play_index -= 1 if player.play_index > 0

                do_play
            end
        end

		# Add a new drive to the library and imports all the mp3 files in it.
		# If the drive exisits just connect an exisiting drive to the library and update all the mp3 files in it.
		#
		# @param params [List<Hash>] With parsed path and literal information.
		# @return [Integer] The number of files imported or songs in connected drive.
		def connect(params=[])
			path_param = params.find{|p| p[:type] == :path}

			if path_param.nil?
				drive_name = params.find{|p| p[:type] == :literal}
				drive = CultomePlayer::Model::Drive.find_by_name(drive_name[:value])
				if drive.nil?
					display c2("An error occured when connecting drive #{drive_name[:value]}. Maybe is mispelled?")
				else
					drive.update_attributes(connected: true)
					drives_registered  << drive
				end

				return CultomePlayer::Model::Song.where(drive_id: drive.id).count()
			else
				# conectamos una unidad nueva
				raise 'directory doesnt exist!' unless Dir.exist?(path_param[:value])

				name_param = params.find{|p| p[:type] == :literal}
				new_drive = CultomePlayer::Model::Drive.find_by_path(path_param[:value])
				if new_drive.nil?
					drives_registered << (new_drive = CultomePlayer::Model::Drive.create(name: name_param[:value], path: path_param[:value]))
				else
					display c2("The drive '#{new_drive.name}' is refering the same path. Update of '#{new_drive.name}' is in progress.")
					new_drive.update_attributes(connected: true)
				end

				music_files = Dir.glob("#{path_param[:value]}/**/*.mp3")
				imported = 0
				to_be_imported = music_files.size

				music_files.each do |file_path|
					begin
                        create_song_from_file(file_path, new_drive)
                        imported += 1
                        display(c4("Importing #{c14(imported.to_s)}/#{c14(to_be_imported.to_s)}...\r"), true)
                    rescue
                        display(c2("Error importing #{file_path}...\r"))
                    end
				end

				display(c14(imported.to_s) + c4(" files imported in drive #{c14(new_drive.name)}"))

				return music_files.size
			end
		end

		# Remove from the library one drive.
		#
		# @param params [List<Hash>] With parsed literal information.
		# @return [Integer] The number of songs in the disconnected drive.
		def disconnect(params=[])
			drive_name = params.find{|p| p[:type] == :literal}
			drive = CultomePlayer::Model::Drive.find_by_name(drive_name[:value])
			if drive.nil?
				raise "An error occured when disconnecting drive #{drive_name[:value]}. Maybe is mispelled?"
			else
				drive.update_attributes(connected: false)
				drives_registered.delete(drive)
			end

			return CultomePlayer::Model::Song.where(drive_id: drive.id).count()
		end

        # Pause the current playback if playing and resume it if paused.
        def pause(params=[])
            turn_pause player.state =~ /PLAYING|RESUMED/ ? :on : :off
        end

        # Change the pause status of the player between PAUSED and RESUMED.
        def toggle_pause
            turn_pause player.state =~ /PLAYING|RESUMED/ ? :on : :off
        end

        # Change the status of the pause.
        #
        # @param state [Symbol] Valid values are :on and :off.
        def turn_pause(state)
            raise 'This command is not valid in this moment.' if current_song.nil?
            raise 'Invalid parameter. Only :on or :off are valids' if state !~ /\Aon|off\Z/

            inverse_pause_state = paused? ? c4("Playback resumed!") : c4("Holding your horses")
            state == :on ?  pause_in_music_player : resume_in_music_player
            
            return inverse_pause_state
        end

        # Stop the current playback.
        def stop(params=[])
            raise 'This command is not valid in this moment.' if current_song.nil?
            stop_in_music_player
        end


        # Fast forward to the current song.
        def ff(params=[])
            raise 'This command is not valid in this moment.' if current_song.nil?

            next_pos = player.song_status[:bytes] + (player.song_status[:frame_size] * seeker_step)
            seek_in_music_player(next_pos)
            return show
        end

        # Fast backward to the current song.
        def fb(params=[])
            raise 'This command is not valid in this moment.' if current_song.nil?

            next_pos = player.song_status[:bytes] - (player.song_status[:frame_size] * seeker_step)
            seek_in_music_player(next_pos)
            return show
        end

		# Check and change the shuffle setting. Without parameters just print the current state of shuffle. 
		# If a literal o numerical parameter is passed, then if its value matches /Y|y|yes|1|si|s|ok/ then 
		# the shuffle is turned on, otherwise is turned off.
		#
		# @param params [List<Hash>] With parsed literal or numerical information.
		# @return [Boolean] The current state of shuffling.
		def shuffle(params=[])
			unless params.empty?
				params.each do |param|
					player.shuffling = is_true_value param[:value].to_s
				end
			end

			display(player.shuffling ? c3("Everyday i'm shuffling") : c2("Shuffle is off"))

			return player.shuffling
		end

        # Change the shuffle status of the player between ON and OFF.
        def toggle_shuffle
            shuffle([{value: !player.shuffling }])
        end

        # Change the status of the shuffle.
        #
        # @param state [Symbol] Valid values are :on and :off.
        def turn_shuffle(state)
            raise 'Invalid parameter. Only :on or :off are valids' if state !~ /\Aon|off\Z/
            shuffle([{value: state}])
        end

		# Begin the current song from the begining.
		def repeat(params=[])
            raise 'This command is not valid in this moment.' if current_song.nil?
            seek_in_music_player(0)
            return current_song
		end

        private

        # Given the parameter passed to the play command, it selects the better response object.
        #
        # @param params [Array<Hash>] The user command' parameter for the command play
        # @return [CultomePlayer::Model::Song|Array<CultomePlayer::Model::Songi>] The object that suit better a response in the player context
        def select_play_return_value(params)
            if params.empty?
                return current_song
            elsif params.size == 1
                case params[0][:type]
                when :number then return current_song
                when /\A(object|literal|criteria)\Z/ then return current_playlist
                end

            else
                return current_playlist
            end
        end

		# Insert a song in the library given its file_path and drive connected.
		#
		# @param file_path [String] The full path to the mp3 file.
		# @param drive [Drive] The connected drive where the file will live.
		# @return [Song] The added song.
		def create_song_from_file(file_path, drive)
			info = extract_mp3_information(file_path)

			raise "ID3 tag information could not be extrated from #{file_path}" if info.nil?

			unless info[:artist].blank?
                info[:artist_id] = CultomePlayer::Model::Artist.find_or_create_by_name(name: info[:artist]).id
			end

			unless info[:album].blank?
				info[:album_id] = CultomePlayer::Model::Album.find_or_create_by_name(name: info[:album]).id
			end

			info[:drive_id] = drive.id
			info[:relative_path] = file_path.gsub("#{drive.path}/", '')

			# buscamos la rola antes de insertarla para evitar duplicados
			song = CultomePlayer::Model::Song.where('drive_id = ? and relative_path = ?', info[:drive_id], info[:relative_path]).first_or_create(info)

			unless info[:genre].blank?
				song.genres << CultomePlayer::Model::Genre.find_or_create_by_name(name: info[:genre])
			end

			return song
		end

        # Extract the ID3 tag information from a mp3 file.
        #
        # @param file_path [String] The full path to a mp3 file.
        # @return [Hash] With the keys: :name, :artist, :album, :track, :duration, :year and :genre. nil if something is wrong.
        def extract_mp3_information(file_path)
            info = nil
            begin
                Mp3Info.open(file_path) do |mp3|
                    info = {
                        name: mp3.tag.title,
                        artist: mp3.tag.artist,
                        album: mp3.tag.album,
                        track: mp3.tag.tracknum,
                        duration: mp3.length,
                        year: mp3.tag1["year"],
                        genre: mp3.tag1["genre_s"]
                    }
                end

                if info[:name].nil?
                    info[:name] = file_path.split('/').last
                end

                return polish_mp3_info(info)
            rescue
                display c2("The file '#{file_path}' could not be added")
                return nil
            end
        end

        # The seeker step to jump between playback positions.
        #
        # @return [Integer] The seeker step
        def seeker_step
            500
        end

        # Given the parameters, generate a playlist for them.
        #
        # @param (see #play)
        # @return [List<Song>] The generated playlist.
        def generate_playlist(params)
            search_criteria = []
            new_playlist = []
            player.playing_library = false

            if params.empty? && current_playlist.blank?
                new_playlist = find_by_query
                player.playing_library = true

                if new_playlist.blank?
                    raise "No music connected yet. Try 'connect /home/user_name/music => music_library' first!"
                end

                player.artist = new_playlist[0].artist unless new_playlist[0].blank?
                player.album = new_playlist[0].album unless new_playlist[0].blank?
            else
                params.each do |param|
                    case param[:type]
                    when /literal|criteria/ then search_criteria << param
                    when :number
                        if player.focus[param[:value].to_i - 1].nil?
                            selected_song = current_playlist[param[:value].to_i - 1]
                            raise "Invalid selection!" if selected_song.nil?
                            player.queue.push selected_song
                        else
                            selected_song = player.focus[param[:value].to_i - 1]
                            raise "Invalid selection!" if selected_song.nil?
                            player.queue.push selected_song
                        end

                    when :object
                        case param[:value]
                        when :library 
                            new_playlist = find_by_query
                            player.playing_library = true
                        when :playlist then new_playlist = current_playlist
                        when /search|search_results/ then new_playlist += player.search_results
                        when :history then new_playlist += player.history
                        when :artist then new_playlist += find_by_query({or: [{id: 5, condition: 'artists.name like ?', value: "%#{ player.artist.name }%"}], and: []})
                        when :album then new_playlist += find_by_query({or: [{id: 5, condition: 'albums.name like ?', value: "%#{ player.album.name }%"}], and: []})

                            # criterios de busqueda avanzados
                        when :recently_added then new_playlist += find_by_query({or: [{id: 6, condition: 'songs.created_at > ?', value: CultomePlayer::Model::Song.maximum('created_at') - (60*60*24)}], and: []})
                        when :recently_played then new_playlist += find_by_query({or: [{id: 7, condition: 'last_played_at > ?', value: CultomePlayer::Model::Song.maximum('last_played_at') - (60*60*24)}], and: []})
                        when :more_played then new_playlist += find_by_query({or: [{id: 8, condition: 'plays > ?', value: CultomePlayer::Model::Song.maximum('plays') - CultomePlayer::Model::Song.average('plays')}], and: []})
                        when :less_played then new_playlist += find_by_query({or: [{id: 9, condition: 'plays < ?', value: CultomePlayer::Model::Song.average('plays')}], and: []})
                        when :populars then new_playlist += find_by_query({or: [{id: 10, condition: 'songs.points > ?', value: CultomePlayer::Model::Song.average('points').ceil.to_i}], and: []})
                        else
                            # intentamos matchear las unidades primero
                            drive = drives_registered.find{|d| d.name.to_sym == param[:value]}
                            if drive.nil?
                                # intetamos matchear por genero
                                new_playlist += CultomePlayer::Model::Song.connected.joins(:genres).where('genres.name like ?', "%#{param[:value].to_s.gsub('_', ' ')}%" )
                            else
                                new_playlist += find_by_query({or: [{id: 11, condition: 'drive_id = ?', value: drive.id}], and: []})
                            end
                        end
                    end # case
                end # do
            end # if

            new_playlist += search(search_criteria) unless search_criteria.blank?

            return new_playlist
        end

        # Retrive songs from connected drives with the given conditions.
        #
        # @param query [Hash] The given conditions for the query
        # @return [List<Song>] The results of the query.
        def find_by_query(query={or: [], and: []})
            # checamos que una condicion que hace que los and's se vuelvan or's
            #   =>  si una condicion del 2..4 se pone dos o mas veces, esa condicion se hace un or
            # TODO: ESTO QUEDO MUY FEO, CAMBIARLO
            (2..4).each do |id_cond|
                if query[:and].count{|cond| cond[:id] == id_cond} > 1
                    # sacamos todas las condiciones de este tipo y las metemos como or's
                    query[:or] = query[:or] + query[:and].select{|cond| cond[:id] == id_cond}
                    query[:and] = query[:and].delete_if{|cond| cond[:id] == id_cond}
                end
            end

            or_condition = query[:or].collect{|c| c[:condition] }.join(' or ')
            and_condition = query[:and].collect{|c| c[:condition] }.join(' and ')

            # armamos la condicion where
            where_clause = or_condition
            if where_clause.blank?
                where_clause = and_condition
            elsif !and_condition.blank?
                where_clause += " and #{and_condition}"
            end

            # preparamos los parametros
            where_params = query.values.collect{|c| c.collect{|v| v[:value] } if !c.blank? }.compact.flatten

            if where_clause.blank?
                CultomePlayer::Model::Song.connected.all
            else
                #Song.joins("left outer join artists on artists.id == songs.artist_id")
                #.joins("left outer join albums on albums.id == songs.album_id")
                CultomePlayer::Model::Song.connected.joins(:artist, :album).where(where_clause, *where_params)
            end
        end

        # Executes a logic to select the next song to play and plays it.
        # Also change the player's state and update de playback count of the song.
        #
        # @return [Song] The new song playing.
        def do_play
            if player.queue.blank?
                return self.next
            end

            player.prev_song = current_song
            player.song = player.queue.shift

            if current_song.nil?
                raise 'There is no song to play'
            end

            if current_song.class == CultomePlayer::Model::Artist
                player.artist = current_song
                return play([{type: :object, value: :artist}])
            elsif current_song.class == CultomePlayer::Model::Album
                player.album = current_song
                return play([{type: :object, value: :album}])
            elsif current_song.class == CultomePlayer::Model::Genre
                return play([{type: :object, value: current_song.name.gsub(' ', '_').to_sym}])
            end

            player.album = current_song.album 
            player.artist = current_song.artist

            begin
                play_in_music_player(current_song.path)
            rescue Exception => e
                raise "Unable_to_play: #{e.message}" #, take_action: true, error_message: e.message)
            end

            # agregamos al contador de reproducciones
            CultomePlayer::Model::Song.increment_counter :plays, current_song.id
            CultomePlayer::Model::Song.update(current_song.id, last_played_at: Time.now)

            return current_song
        end

        # Clean and format the track information.
        # @param info [Hash] With the keys: :name, :artist, :album, :track, :duration, :year and :genre.
        # @return [Hash] The same hash but with polished values.
        def polish_mp3_info(info)
            [:genre, :name, :artist, :album].each{|k| info[k] = info[k].downcase.strip.titleize unless info[k].nil? }
            [:track, :year].each{|k| info[k] = info[k].to_i if info[k] =~ /\A[\d]+\Z/ }
            info[:duration] = info[:duration].to_i

            info
        end

        # The collection of songs not yet played in the current playlist when the shuffle is on.
        #
        # @return [Array] with the songs not yet played.
        def songs_not_played_in_playlist 
            @songs_not_played_in_playlist ||= []
        end
    end
end
