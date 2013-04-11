require 'persistence'
require 'shellwords'

class BasicCommandSet

	FAST_FORWARD_STEP = 500

	def initialize(player)
		@p = player
	end

	def get_registry
		{
		play: {help: "Create and inmediatly plays playlists", params_format: "(<number>|<criteria>|<object>|<literal>)*"},
		enqueue: {help: "Append the created playlist to the current playlist", params_format: "(<number>|<criteria>|<object>|<literal>)*"},
		search: {help: "Find inside library for song with the given criteria.", params_format: "(<criteria>|<object>|<literal>)*"},
		show: {help: "Display information about status, objects and library.", params_format: "<object>"},
		pause: {help: "Pause playback.", params_format: ""},
		stop: {help: "Stops playback.", params_format: ""},
		:next => {help: "Play the next song in the queue.", params_format: "<number>"},
		prev: {help: "Play the previous song from the history.", params_format: ""},
		connect: {help: "Add files to the library.", params_format: "<path> => <literal>"},
		disconnect: {help: "Remove filesfrom the library.", params_format: "<literal>"},
		quit: {help: "Exit the player.", params_format: ""},
		ff: {help: "Fast forward 5 sec.", params_format: ""},
		fb: {help: "Fast backward 5 sec.", params_format: ""},
		shuffle: {help: "Check and change the status of shuffle.", params_format: "<number>|<literal>"},
		repeat: {help: "Repeat the current song", params_format: ""},
		kill: {help: "Delete from disk the current song", params_format: ""},
		}
	end

	def quit(params=[])
		@p.running = false
		@p.player.stop
	end

	def stop(params=[])
		@p.player.stop
	end

	# parameter types: literal, criteria
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
			end
		end

		@p.display(@p.search = @p.focus = find_by_query(query).to_a)

		@p.search
	end

	def enqueue(params=[])
		pl = generate_playlist(params)
		@p.playlist = @p.focus = @p.playlist + pl 
	end

	# parameter types: literal, criteria::: object, number
	def play(params=[])
		pl = generate_playlist(params)
		# si se encolan
		unless pl.blank?
			@p.playlist = @p.focus = pl
			@p.play_index = -1
			@p.queue = []
		end

		@p.history.push @p.song unless @p.song.nil?
		do_play
	end

	def generate_playlist(params)
		search_criteria = []
		new_playlist = []
		@p.is_playing_library = false

		if params.empty? && @p.playlist.blank?
			new_playlist = find_by_query
			@p.is_playing_library = true

			if new_playlist.blank?
				@p.display "No music connected yet. Try 'connect /home/csoria/music => music_library' first!"
				return nil
			end

			@p.artist = new_playlist[0].artist unless new_playlist[0].blank?
			@p.album = new_playlist[0].album unless new_playlist[0].blank?
		else
			params.each do |param|
				case param[:type]
					when /literal|criteria/ then search_criteria << param
					when :number
						if @p.focus[param[:value].to_i - 1].nil?
							@p.queue.push @p.playlist[param[:value].to_i - 1]
						else
							@p.queue.push @p.focus[param[:value].to_i - 1]
						end
					when :object
						case param[:value]
							when :library 
								new_playlist = find_by_query
								@p.is_playing_library = true
							when :playlist then new_playlist = @p.playlist
							when :search then new_playlist += @p.search
							when :history then new_playlist += @p.history
							when :artist then new_playlist += find_by_query({or: [{id: 5, condition: 'artists.name like ?', value: "%#{ @p.artist.name }%"}], and: []})
							when :album then new_playlist += find_by_query({or: [{id: 5, condition: 'albums.name like ?', value: "%#{ @p.album.name }%"}], and: []})

							# criterios de busqueda avanzados
							when :recently_added then new_playlist += find_by_query({or: [{id: 6, condition: 'songs.created_at > ?', value: Song.maximum('created_at') - (60*60*24)}], and: []})
							when :recently_played then new_playlist += find_by_query({or: [{id: 7, condition: 'last_played_at > ?', value: Song.maximum('last_played_at') - (60*60*24)}], and: []})
							when :more_played then new_playlist += find_by_query({or: [{id: 8, condition: 'plays > ?', value: Song.maximum('plays') - Song.average('plays')}], and: []})
							when :less_played then new_playlist += find_by_query({or: [{id: 9, condition: 'plays < ?', value: Song.average('plays')}], and: []})
							when :populars then new_playlist += find_by_query({or: [{id: 10, condition: 'songs.points > ?', value: Song.average('points').ceil.to_i}], and: []})
							else
								# intentamos matchear las unidades primero
								drive = @p.drives.find{|d| d.name.to_sym == param[:value]}
								if drive.nil?
									# intetamos matchear por genero
									new_playlist += Song.connected.joins(:genres).where('genres.name like ?', "%#{param[:value].to_s.gsub('_', ' ')}%" )
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

	def shuffle(params=[])
		unless params.empty?
			params.each do |param|
				@p.is_shuffling = is_true_value param[:value]
			end
		end
		@p.display(@p.is_shuffling ? "Everyday i'm shuffling" : "Shuffle is off")

	end

	def next(params=[])
		if @p.play_index + 1 < @p.playlist.size
			@p.history.push @p.song unless @p.song.nil?

			if @p.is_shuffling
				@p.queue.push @p.playlist[rand(@p.playlist.size)]
			else
				@p.play_index += 1
				@p.queue.push @p.playlist[@p.play_index]
			end

			do_play
		else
			@p.display "No more songs in playlist!"
		end
	end

	def prev(params=[])
		if @p.history.blank?
			@p.display "Thre is no files in history"
		else
			@p.queue.unshift @p.history.pop
			@p.play_index -= 1 if @p.play_index > 0

			do_play
		end
	end

	def do_play
		if @p.queue.blank?
			return self.next
		end

		old_song = @p.song
		@p.song = @p.queue.shift

		# antes de cambiar de cancion calificamos la actual rola
		#@taste.calculate_weight(
			#old_song,
			#@song
		#) unless old_song.nil?

		if @p.song.nil?
			@p.display 'There is no song to play' 
			return nil
		end

		if @p.song.class == Artist
			@p.artist = @p.song
			return play([{type: :object, value: :artist}])
		elsif @p.song.class == Album
			@p.album = @p.song
			return play([{type: :object, value: :album}])
		elsif @p.song.class == Genre
			return play([{type: :object, value: @p.song.name.gsub(' ', '_').to_sym}])
		end

		@p.album = @p.song.album 
		@p.artist = @p.song.artist

		@p.player.play(@p.song.path)

		# agregamos al contador de reproducciones
		Song.increment_counter :plays, @p.song.id
		Song.update(@p.song.id, last_played_at: Time.now)

		@p.display @p.song

		@p.song
	end


	def show(params=[])
		if params.blank?
			@p.display @p.song
			show_progress @p.song 
		else
			params.each do |param|
				case param[:type]
					when :object
						case param[:value]
							when :library then @p.focus = obj = find_by_query
							when :artists then @p.focus = obj = Artist.all
							when :albums then @p.focus = obj = Album.all
							when :genres then @p.focus = obj = Genre.all
							when /playlist|search|history/ then @p.focus = obj = @p.instance_variable_get("@#{param[:value]}")
							when /artist|album|drives/ then obj = @p.instance_variable_get("@#{param[:value]}")
							when :recently_added then @p.focus = obj = Song.where('created_at > ?', Song.maximum('created_at') - (60*60*24) )
							else
								drive = @p.drives.find{|d| d.name.to_sym == param[:value]}
								@p.focus = obj = Song.where('drive_id = ?', drive.id).to_a unless drive.nil?
						end
					else
						obj = @p.song
				end # case
				@p.display(obj)
			end # do
		end # if
	end

	def show_progress(song)
		actual = @p.song_status["mp3.position.microseconds"] / 1000000
		percentage = ((actual * 100) / song.duration) / 10
		@p.display "#{to_time(actual)} <#{"=" * (percentage*2)}#{"-" * ((10-percentage)*2)}> #{to_time(song.duration)}"
	end

	def pause(params=[])
		@p.status =~ /PLAYING|RESUMED/ ? @p.player.pause : @p.player.resume
	end

	def connect(params=[])
		path_param = params.find{|p| p[:type] == :path}

		if path_param.nil?
			drive_name = params.find{|p| p[:type] == :literal}
			drive = Drive.find_by_name(drive_name[:value])
			if drive.nil?
				@p.display("An error occured when connecting drive #{drive_name[:value]}. Maybe is mispelled?")
			else
				drive.update_attributes(connected: true)
				@p.drives << drive
			end

			return Song.where(drive_id: drive.id).count()
		else
			# conectamos una unidad nueva
			return nil unless Dir.exist?(path_param[:value])

			name_param = params.find{|p| p[:type] == :literal}
			@p.drives << (new_drive = Drive.create(name: name_param[:value], path: path_param[:value]))

			music_files = Dir.glob("#{path_param[:value]}/**/*.mp3")
			imported = 0
			to_be_imported = music_files.size

			music_files.each do |file_path|
				create_song_from_file(file_path, new_drive)
				imported += 1
				@p.display "Importing #{imported}/#{to_be_imported}..."
			end

			return music_files.size
		end
	end

	def disconnect(params=[])
		drive_name = params.find{|p| p[:type] == :literal}
		drive = Drive.find_by_name(drive_name[:value])
		if drive.nil?
			@p.display("An error occured when disconnecting drive #{drive_name[:value]}. Maybe is mispelled?")
		else
			drive.update_attributes(connected: false)
			@p.drives.delete(drive)
		end

		return Song.where(drive_id: drive.id).count()
	end

	def ff(params=[])
		next_pos = @p.song_status["mp3.position.byte"] + (@p.song_status["mp3.frame.size.bytes"] * FAST_FORWARD_STEP)
		@p.player.seek(next_pos)
	end

	def fb(params=[])
		next_pos = @p.song_status["mp3.position.byte"] - (@p.song_status["mp3.frame.size.bytes"] * FAST_FORWARD_STEP)
		@p.player.seek(next_pos)
	end

	def kill(params=[])
		if get_confirmation("Are you sure you want to delete #{@p.song} ???")
			# detenemos la reproduccion
			self.stop

			path = Shellwords.escape("#{@p.song.drive.path}/#{@p.song.relative_path}")
			system("mv #{path} ~/tmp/#{rand()}.mp3")

			if $?.exitstatus == 0
				@p.song.delete
				@p.display("Song deleted!")
			else
				@p.display("An error occurred when deleting the song #{@p.song}")
			end
			
			# reanudamos la reproduccion
			self.next
		end
	end

	def repeat(params=[])
		@p.player.seek(0)
	end

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
			Song.connected.all
		else
			#Song.joins("left outer join artists on artists.id == songs.artist_id")
			#.joins("left outer join albums on albums.id == songs.album_id")
			Song.connected.joins(:artist, :album)
			.where(where_clause, *where_params)
		end
	end

	def create_song_from_file(file_path, drive)
		info = extract_mp3_information(file_path)

		return nil if info.nil?

		unless info[:artist].blank?
			info[:artist_id] = Artist.find_or_create_by_name(name: info[:artist]).id
		end

		unless info[:album].blank?
			info[:album_id] = Album.find_or_create_by_name(name: info[:album]).id
		end

		info[:drive_id] = drive.id
		info[:relative_path] = file_path.gsub("#{drive.path}/", '')

		song = Song.create(info)

		unless info[:genre].blank?
			song.genres << Genre.find_or_create_by_name(name: info[:genre])
		end

		return song
	end
end

