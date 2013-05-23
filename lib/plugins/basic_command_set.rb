require 'cultome/plugin'
require 'cultome/persistence'
require 'cultome/exception'
require 'cultome/user_input'

# Plugin to handle basic commands of the player.
module Plugin
	class BasicCommandSet < PluginBase
		include UserInput

		# Get and store a copy of the CultomePlayer instance to operate with.
		# Initialize two utility registers in Album and Artist models for unknown album or artist.
		#
		# @param player [CultomePlayer] An instance of the player to operate with.
		def initialize(player, config)
			super(player, config)
			# checamos si estan los registros default
			Album.find_or_create_by_id(id: 0, name: "unknown")
			Artist.find_or_create_by_id(id: 0, name: "unknown")
		end

		# Register the commands: play, enqueue, search, show, pause, stop, next, prev, connect, disconnect, quit, ff, fb, shuffle, repeat.
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{
				play: {
					help: "Create and inmediatly plays playlists",
					params_format: "(<number>|<criteria>|<object>|<literal>)*",
					usage: <<HELP
Creates a playlist and make it active right away but it can also play an elements of the focus list.
When a new playlist is created, some other playlist are created, among them the focus list. You can think of the focus list as "The song list last showed in screen".
This playlist allows the player to know what you are meaning when you type a number as parameter. This playlist is dynamic and changes when some song list is displayed in the screen, for example when a search is done (search strawberry) or when an object is showed (show @history).

The parameters provided are used to create the new playlist. Let review how the mix to create the playlist:
	1.  When criteria parameters are used, diferents criterios makes an AND condition, and similar criterios make an OR condition. For example:
		* play a:Gorillaz b:Demon
		Search for songs with artists that contains 'Gorillaz' in theirs names AND 'Demon' in theirs albums names. Different criterios ('a' and 'b') makes an AND condition.
		* play a:Gorillaz a:Sabbath
		Search for songs with artists that contains 'Gorillaz' OR 'Sabbath' in theirs names. Same criterios ('a' and 'a') makes an OR condition.

	2.  When number parameters are used, all the elements in the focus list are played.
		* play 1 4 5
		Plays the first, fourth and fiveth songs in the focus list. But dont add them to the current playlist.

	3.  When object parameters are used, all the elements in the objects are used to create the new playlist.
		* play @history @search
	
	4.  When literal parameters are used, this are used as all-criterias match, so
		* play one two
		Play song with the strings 'one' or 'two' in their title, artist's name or album's name in it.

Any parameter type and quantity can be used to create a playlist.

HELP
				},

				enqueue: {
					help: "Append the created playlist to the current playlist",
				   	params_format: "(<number>|<criteria>|<object>|<literal>)*",
					usage: <<HELP
See 'help play' for more information about parameters.

The only diference with play command is that this command append its results to the current playlist instead of create a new one.
HELP
				},

				search: {
					help: "Find inside library for song with the given criteria.",
				   	params_format: "(<criteria>|<object>|<literal>)*",
					usage: <<HELP
See 'help play' for more information about parameters.

The search command search song in the library and display the results in the screen. The results change the focus list.

HELP
				},

				show: {
					help: "Display information about status, objects and library.", 
					params_format: "[<object>]",
					usage: <<HELP
If a parameter is provided the object is shown in the screen, for example
	* show @playlist
	Display the current playlist in screen.
	* show @history
	Display the playback history of the current session.

The following are a list of valid player objects:
	* playlist
	* search
	* history
	* artist
	* album
	* drives
	* queue
	* focus

Also exist pseudo-objects in the scope of show command to facilitate the exploration of library. The list is the next:
	* library        : The complete list of songs in the library
	* artists        : The list of artists in the library
	* albums         : The list of albums in the library
	* genres         : The list of genres in the library
	* recently_added : The list of song that were recently added to the library.
	* genre          : The songs with the same genres as the current playing

These objects can be used as any other object in the scope of this command, for example:
	* show @artists
	Display a list of artists from the library.

When an object is passed but not finded among the player objects nor the pseudo-object, the show command look for drives named like that, for example:
	* show @my_drive
	Display the list of song in the drive named 'my_drive'.

HELP
				},

				pause: {
					help: "Pause playback.",
				   	params_format: "",
					usage: <<HELP
Pause the playback of the current song. This command has a state and is toggled every time is invoked. So if the song is playing and you type 'pause', the playback pause and the state of the player change to PAUSED, when you type again 'pause', the playback resume and the player states is changed to RESUMED.

HELP
				},

				stop: {
					help: "Stops playback.",
				   	params_format: "",
					usage: <<HELP
Stop the playback and there ir no way to resume where you were. So using 'play' won't resume the last song played.
HELP
				},

				:next => {
					help: "Play the next song in the queue.",
				   	params_format: "<number>",
					usage: <<HELP
When next is invoked, the calculation for the next song is made. If shuffle is on, the next song is defined by selecting a song not played yet, if remains any, if not, the complete current playlist is reprogramed to be played again.
HELP
				},

				prev: {
					help: "Play the previous song from the history.",
				   	params_format: "",
					usage: <<HELP
Extract the latest song from history and play it. The history object is modified by this action.
HELP
				},

				connect: {
					help: "Add files to the library.",
				   	params_format: "<path> => <literal>",
					usage: <<HELP
Tells the player to go to the path and search for mp3 files and add them to the library under the drive name.
	* connect /home/user/music => main

You can add as many drives as you like. Once connected the drive needs not to be connected again, unless disconnected explicitly.

The player dont scan the drive for changes, if you want to update your drive, just type the connect method with the same path and an update will be made instead of a insert. For example, if you connect one drive 'downloads'
	* connect /home/user/download => downloads
And later, new song came to this folder, you can refresh the drive with the next
	* connect /home/user/download => no_matter
The name dont matter as the path is the same. The trailing dashes are ignored. In this forma the new songs are added but the older persist (no duplications).

If you only want to re-connect the drive without scanning for new media just type:
	* connect <drive_name>

HELP
				},

				disconnect: {
					help: "Remove filesfrom the library.",
				   	params_format: "<literal>",
					usage: <<HELP
See 'help connect' for more information.

Disconnect a previously connected drive. This mean the songs in this drive are no longer availables to be played or searched.

HELP
				},

				quit: {
					help: "Exit the player.",
				   	params_format: "",
					usage: <<HELP
Shutdown the player. In this moment is when the player save the plugin configurations of this session, for example, created aliases.

HELP
				},

				ff: {
					help: "Fast forward the current playback.",
				   	params_format: "",
					usage: <<HELP
The amount of time can be determined changing the parameter @config["seeker_step"] (default: 500)

HELP
				},

				fb: {
					help: "Fast backward the current playback.",
				   	params_format: "",
					usage: <<HELP
The amount of time can be determined changing the parameter @config["seeker_step"] (default: 500)

HELP
				},

				shuffle: {
					help: "Check and change the status of shuffle.",
				   	params_format: "<number>|<literal>",
					usage: <<HELP
Toggle the shuffling of playback. Without parameter shows the state of the shuffle (on|off).

This command support a variety of true-like values to indicate the shuffle must be turn on, for example all the following turn it on:
	* shuffle on
	* shuffle yes
	* shuffle 1

Same case for turn it off:
	* shuffle off
	* shuffle no
	* shuffle 0

HELP
				},

				repeat: {
					help: "Repeat the current song",
				   	params_format: "",
					usage: <<HELP
Start the playback of the current song again from the beginning.

HELP
				},
			}
		end

		# Create and play a playlist with the results of parameters criterios.
		#
		# @param params [List<Hash>] The hashes contains the keys, dependending on the parameter type, :value, :type, :criteria.
		# @return (see #do_play)
		def play(params=[])
			pl = generate_playlist(params)
			# si se encolan
			unless pl.blank?
				@cultome.playlist = @cultome.focus = pl
				@cultome.play_index = -1
				@cultome.queue = []
				@not_played = (0...@cultome.playlist.size).to_a
			end

			@cultome.history.push @cultome.song unless @cultome.song.nil?
			do_play
		end

		# Add songs to the current playlist.
		#
		# @param (see #play)
		# @return [List<Song>] The new playlist.
		def enqueue(params=[])
			pl = generate_playlist(params)
			@cultome.playlist = @cultome.focus = @cultome.playlist + pl 
			@not_played << @cultome.playlist.size
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
					when :artist then query[:and] << {id: 12, condition: 'artists.id = ?', value: @cultome.artist.id}
					when :album then query[:and] << {id: 13, condition: 'albums.id = ?', value: @cultome.album.id}
					end
				end
			end

			results = find_by_query(query).to_a
			if results.empty?
				display(c2("No results found!"))
			else
				display(@cultome.search = @cultome.focus = results)
			end

			return results
		end

		# Display an object in the screen. If no parameter is proveided, shows the progress of the current song.
		#
		# @param params [List<Hash>] With parsed player's object information.
		# @return [String] The message displayed.
		def show(params=[])
			if params.blank?
				display @cultome.song
				show_progress 
			else
				params.each do |param|
					case param[:type]
					when :object
						case param[:value]
						when :library then @cultome.focus = obj = find_by_query
						when :artists then @cultome.focus = obj = Artist.order(:name).all
						when :albums then @cultome.focus = obj = Album.order(:name).all
						when :genres then @cultome.focus = obj = Genre.order(:name).all
						when /playlist|search|history/ then @cultome.focus = obj = @cultome.instance_variable_get("@#{param[:value]}")
						when /artist|album|queue|focus/ then obj = @cultome.instance_variable_get("@#{param[:value]}")
						when /drives/ then obj = Drive.all.to_a
						when :recently_added then @cultome.focus = obj = Song.where('created_at > ?', Song.maximum('created_at') - (60*60*24) )
						when :genre then @cultome.focus = obj = Song.connected.joins(:genres).where('genres.name in (?)', @cultome.song.genres.collect{|g| g.name }).to_a
						else
							# intentamos matchear las unidades primero
							drive = drives.find{|d| d.name.to_sym == param[:value]}
							unless drive.nil?
								@cultome.focus = obj = Song.where('drive_id = ?', drive.id).to_a unless drive.nil?
							end
						end
					else
						obj = @cultome.song
					end # case
					display(obj)
				end # do
			end # if
		end

		# Pause the current playback if playing and resume it if paused.
		def pause(params=[])
			@cultome.status =~ /PLAYING|RESUMED/ ? @cultome.player.pause : @cultome.player.resume
		end

		# Stop the current playback.
		def stop(params=[])
			@cultome.player.stop
		end

		# Select the next song to be played and plays it.
		#
		# @return (see #do_play)
		def next(params=[])
			if @cultome.play_index + 1 < @cultome.playlist.size
				@cultome.history.push @cultome.song unless @cultome.song.nil?

				if @cultome.is_shuffling
					# Para tener un mejor random hacemos qur toque 
					# primero toda la playlist antes de repetir las rolas
					if @not_played.empty?
						@not_played = (0...@cultome.playlist.size).to_a
					end

					idx = @not_played.sample
					@not_played.delete(idx)
					@cultome.queue.push @cultome.playlist[idx]
				else
					@cultome.play_index += 1
					@cultome.queue.push @cultome.playlist[@cultome.play_index]
				end

				do_play
			else
				display c2("No more songs in playlist!")
			end
		end

		# Get the latest song from history and plays it.
		#
		# @return (see #do_play)
		def prev(params=[])
			if @cultome.history.blank?
				display c2("There is no files in history")
			else
				@cultome.queue.unshift @cultome.history.pop
				@cultome.play_index -= 1 if @cultome.play_index > 0

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
				drive = Drive.find_by_name(drive_name[:value])
				if drive.nil?
					display c2("An error occured when connecting drive #{drive_name[:value]}. Maybe is mispelled?")
				else
					drive.update_attributes(connected: true)
					drives << drive
				end

				return Song.where(drive_id: drive.id).count()
			else
				# conectamos una unidad nueva
				return nil unless Dir.exist?(path_param[:value])

				name_param = params.find{|p| p[:type] == :literal}
				new_drive = Drive.find_by_path(path_param[:value])
				if new_drive.nil?
					drives << (new_drive = Drive.create(name: name_param[:value], path: path_param[:value]))
				else
					display c2("The drive '#{new_drive.name}' is refering the same path. Update of '#{new_drive.name}' is in progress.")
					new_drive.update_attributes(connected: true)
				end

				music_files = Dir.glob("#{path_param[:value]}/**/*.mp3")
				imported = 0
				to_be_imported = music_files.size

				music_files.each do |file_path|
					create_song_from_file(file_path, new_drive)
					imported += 1
					display(c4("Importing #{c14(imported.to_s)}/#{c14(to_be_imported.to_s)}...\r"), true)
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
			drive = Drive.find_by_name(drive_name[:value])
			if drive.nil?
				display c2("An error occured when disconnecting drive #{drive_name[:value]}. Maybe is mispelled?")
			else
				drive.update_attributes(connected: false)
				drives.delete(drive)
			end

			return Song.where(drive_id: drive.id).count()
		end

		# Stop the player and set the @running flag to false.
		def quit(params=[])
			@cultome.running = false
			@cultome.player.stop
			@cultome.save_configuration
		end

		# Fast forward to the current song.
		def ff(params=[])
			next_pos = @cultome.song_status["mp3.position.byte"] + (@cultome.song_status["mp3.frame.size.bytes"] * seeker_step)
			@cultome.player.seek(next_pos)
		end

		# Fast backward to the current song.
		def fb(params=[])
			next_pos = @cultome.song_status["mp3.position.byte"] - (@cultome.song_status["mp3.frame.size.bytes"] * seeker_step)
			@cultome.player.seek(next_pos)
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
					@cultome.is_shuffling = is_true_value param[:value]
				end
			end
			display(@cultome.is_shuffling ? c3("Everyday i'm shuffling") : c2("Shuffle is off"))

			return @cultome.is_shuffling
		end

		# Begin the current song from the begining.
		def repeat(params=[])
			@cultome.player.seek(0)
		end

		private

		def seeker_step
			@config["seeker_step"] ||= 500
		end

		# Given the parameters, generate a playlist for them.
		#
		# @param (see #play)
		# @return [List<Song>] The generated playlist.
		def generate_playlist(params)
			search_criteria = []
			new_playlist = []
			@cultome.is_playing_library = false

			if params.empty? && @cultome.playlist.blank?
				new_playlist = find_by_query
				@cultome.is_playing_library = true

				if new_playlist.blank?
					display c2("No music connected yet. Try 'connect /home/user_name/music => music_library' first!")
					return nil
				end

				@cultome.artist = new_playlist[0].artist unless new_playlist[0].blank?
				@cultome.album = new_playlist[0].album unless new_playlist[0].blank?
			else
				params.each do |param|
					case param[:type]
					when /literal|criteria/ then search_criteria << param
					when :number
						if @cultome.focus[param[:value].to_i - 1].nil?
							@cultome.queue.push @cultome.playlist[param[:value].to_i - 1]
						else
							@cultome.queue.push @cultome.focus[param[:value].to_i - 1]
						end
					when :object
						case param[:value]
						when :library 
							new_playlist = find_by_query
							@cultome.is_playing_library = true
						when :playlist then new_playlist = @cultome.playlist
						when :search then new_playlist += @cultome.search
						when :history then new_playlist += @cultome.history
						when :artist then new_playlist += find_by_query({or: [{id: 5, condition: 'artists.name like ?', value: "%#{ @cultome.artist.name }%"}], and: []})
						when :album then new_playlist += find_by_query({or: [{id: 5, condition: 'albums.name like ?', value: "%#{ @cultome.album.name }%"}], and: []})

							# criterios de busqueda avanzados
						when :recently_added then new_playlist += find_by_query({or: [{id: 6, condition: 'songs.created_at > ?', value: Song.maximum('created_at') - (60*60*24)}], and: []})
						when :recently_played then new_playlist += find_by_query({or: [{id: 7, condition: 'last_played_at > ?', value: Song.maximum('last_played_at') - (60*60*24)}], and: []})
						when :more_played then new_playlist += find_by_query({or: [{id: 8, condition: 'plays > ?', value: Song.maximum('plays') - Song.average('plays')}], and: []})
						when :less_played then new_playlist += find_by_query({or: [{id: 9, condition: 'plays < ?', value: Song.average('plays')}], and: []})
						when :populars then new_playlist += find_by_query({or: [{id: 10, condition: 'songs.points > ?', value: Song.average('points').ceil.to_i}], and: []})
						else
							# intentamos matchear las unidades primero
							drive = drives.find{|d| d.name.to_sym == param[:value]}
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

		# Executes a logic to select the next song to play and plays it.
		# Also change the player's state and update de playback count of the song.
		#
		# @return [Song] The new song playing.
		def do_play
			if @cultome.queue.blank?
				return self.next
			end

			@cultome.prev_song = @cultome.song
			@cultome.song = @cultome.queue.shift

			if @cultome.song.nil?
				display c2('There is no song to play')
				return nil
			end

			if @cultome.song.class == Artist
				@cultome.artist = @cultome.song
				return play([{type: :object, value: :artist}])
			elsif @cultome.song.class == Album
				@cultome.album = @cultome.song
				return play([{type: :object, value: :album}])
			elsif @cultome.song.class == Genre
				return play([{type: :object, value: @cultome.song.name.gsub(' ', '_').to_sym}])
			end

			@cultome.album = @cultome.song.album 
			@cultome.artist = @cultome.song.artist

			begin
				@cultome.player.play(@cultome.song.path)
			rescue Exception => e
				raise CultomePlayerException.new(:unable_to_play, take_action: true, error_original: e.message)
			end

			# agregamos al contador de reproducciones
			Song.increment_counter :plays, @cultome.song.id
			Song.update(@cultome.song.id, last_played_at: Time.now)

			display @cultome.song

			@cultome.song
		end

		# Show an ASCII bar with the time progress of the current song.
		#
		# @return [String] An ASCII bar with the time progress of the current song.
		def show_progress
			actual = @cultome.song_status["mp3.position.microseconds"] / 1000000
			percentage = ((actual * 100) / @cultome.song.duration) / 10
			display c4("#{to_time(actual)} <#{"=" * (percentage*2)}#{"-" * ((10-percentage)*2)}> #{to_time(@cultome.song.duration)}")
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
				Song.connected.all
			else
				#Song.joins("left outer join artists on artists.id == songs.artist_id")
				#.joins("left outer join albums on albums.id == songs.album_id")
				Song.connected.joins(:artist, :album)
				.where(where_clause, *where_params)
			end
		end

		# Insert a song in the library given its file_path and drive connected.
		#
		# @param file_path [String] The full path to the mp3 file.
		# @param drive [Drive] The connected drive where the file will live.
		# @return [Song] The added song.
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

			# buscamos la rola antes de insertarla para evitar duplicados
			song = Song.where('drive_id = ? and relative_path = ?', info[:drive_id], info[:relative_path]).first_or_create(info)

			unless info[:genre].blank?
				song.genres << Genre.find_or_create_by_name(name: info[:genre])
			end

			return song
		end

		def drives
			@cultome.drives ||= Drive.all.to_a
		end
	end
end

