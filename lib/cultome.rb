require 'shellwords'
require 'taste_analizer'
require 'gesture_analizer'
require 'user_input'
require 'readline'
require 'persistence'
require 'player_listener'
require 'helper'
require 'active_support'

# TODO
#  - Probar que pasa cuando la cancion no tiene informacion del album o artista
#  - Agregar el genero a los objetos del reproductor
#  - Revisar las conexiones la BD, se estan quedado colgadas
#  - meter scopes para busquedas "rapidas" (ultimos reproducidos, mas tocados, meos tocados)
#  - Meter visualizaciones ASCII
#  - Conectar y deconectar unidades
#  - Elimnar palabras cortitas de las busquedas como AND, THE, etc
# 
#
# ERRORS
#  - Manejar la situacion de que la rola no cargue correctamente
#  - Como primera accion, el 'play absolution' toca otra cancion
#  - A veces se atora cuando termina una cancion y no toca la siguiente
#  - Clear objetos como queue y playlist
#  - Comporatmiento erratico con la queue
#

class CultomePlayer
	include UserInput
	include PlayerListener
	include Helper

	FAST_FORWARD_STEP = 250

	attr_reader :playlist
	attr_reader :search
	attr_reader :history
	attr_reader :queue

	attr_reader :song
	attr_reader :artist
	attr_reader :album
	# para el taster
	attr_reader :song_status
	attr_reader :current_command
	attr_reader :is_playing_library
	attr_reader :is_shuffling

	def initialize
		@player = Player.new(self)
		@search = []
		@playlist = []
		@history = []
		@queue = []
		@song = nil
		@artist = nil
		@album = nil
		@play_index = -1
		@prompt = 'cultome> '
		@status = :STOPPED
		@song_status = {}
		@focus = nil
		@drives = Drive.all.to_a
		@last_cmds = []
		@is_shuffling = true
		@taste = TasteAnalizer.new(self)
		@current_command = nil
		@gestures = GestureAnalizer.new
	end

	def start
		display "Iniciando!" # aqui poner una frase humorisitca aleatoria
		@running = true

		while(@running) do
			execute Readline::readline(@prompt, true)
		end
		display "Bye!" # aqui poner una frase humorisitca aleatoria
	end

	def execute(user_input)
		begin
			cmds = parse(user_input)
			if cmds.empty?
				cmds = @last_cmds
			else
				@last_cmds = cmds
			end

			cmds.each do |cmd|
				if respond_to? cmd[:command]
					@current_command = cmd
					@gestures.add_command(cmd)
					return send(cmd[:command], cmd[:params])
				end
			end
		rescue Exception => e
			display e.message
			# podriamos indicar que la cancion no toca simplemente y sacarla
			send(:next) unless e.message =~ /Invalid command/
		end
	end

	def help(params=[])
		if params.empty?
			display("The following commands are valids:")
			COMMANDS.each{|key, map| display("  #{key.ljust(15)} #{map[:help]}")}
			display("\nView more details for a command typing 'help <command>'\n")
		else
			cmd = params[0][:value]
			map = COMMANDS[cmd]
			display("Usage: #{cmd} #{ map[:params_format] }")
		end

		display("\nThe following are the parameters types:")
		display("  #{"number".ljust(15)}A integer value. Normally limited by the focused object.")
		display("  #{"literal".ljust(15)}Any string of characters. If spaces are required, wrap the string with \" or '")
		display("  #{"object".ljust(15)}One of the playes's objects. The following are available:")
		display("#{"".ljust(20)}@playlist: The current playlist.")
		display("#{"".ljust(20)}@song: The current song playing.")
		display("#{"".ljust(20)}@artist: The artist from the current song playing.")
		display("#{"".ljust(20)}@album: The album from the current song playing.")
		display("#{"".ljust(20)}@history: The history playlist.")
		display("#{"".ljust(20)}@search: the playlist with the results of the lastest search.")
		display("#{"".ljust(20)}@library: The playlist of the complete library..")
		display("  #{"criteria".ljust(15)}A key-value pair in the format <key>:<literal>. Valid keys are:")
		display("#{"".ljust(20)}a: stand for Artist.")
		display("#{"".ljust(20)}b: stand for Album.")
		display("#{"".ljust(20)}t: stand for Title.")
		display("  #{"path".ljust(15)}A valid path inside local filesystem.")
	end

	def quit(params=[])
		@running = false
		@player.stop
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
				elsif param[:criteria] == :s then query[:and] << {id: 4, condition: 'songs.name like ?', value: param_value} end
			end
		end

		display(@search = @focus = find_by_query(query).to_a)

		@search
	end

	def enqueue(params=[])
		play(params, true)
	end

	# parameter types: literal, criteria::: object, number
	def play(params=[], enqueue=false)
		search_criteria = []
		new_playlist = []
		@is_playing_library = false

		if params.empty? && @playlist.blank?
			new_playlist = find_by_query
			@is_playing_library = true

			if new_playlist.blank?
				display "No music connected yet. Try 'connect /home/csoria/music => music_library' first!"
				return nil
			end

			# set_playlist results # todas las canciones
			@artist = new_playlist[0].artist unless new_playlist[0].blank?
			@album = new_playlist[0].album unless new_playlist[0].blank?
		else
			params.each do |param|
				case param[:type]
					when /literal|criteria/ then search_criteria << param
					when :number
						if @focus[param[:value].to_i - 1].nil?
							@queue.push @playlist[param[:value].to_i - 1]
						else
							@queue.push @focus[param[:value].to_i - 1]
						end
					when :object
						case param[:value]
							when :library 
								new_playlist = find_by_query
								@is_playing_library = true
							when :playlist then new_playlist = @playlist
							when :search then new_playlist += @search
							when :history then new_playlist += @history
							when :artist then new_playlist += find_by_query({or: [{id: 5, condition: 'artists.name like ?', value: "%#{ @artist.name }%"}], and: []})
							when :album then new_playlist += find_by_query({or: [{id: 5, condition: 'albums.name like ?', value: "%#{ @album.name }%"}], and: []})
							when :recent_added then new_playlist += Song.where('created_at > ?', Song.maximum('created_at') - (60*60*24) )
							else
								drive = @drives.find{|d| d.name.to_sym == param[:value]}
								new_playlist += Song.where('drive_id = ?', drive.id).to_a unless drive.nil?
						end
				end # case
			end # do
		end # if

		new_playlist += search(search_criteria) unless search_criteria.blank?

		# si se encolan
		if enqueue
			@playlist = @focus = @playlist + new_playlist 
		else
			set_playlist(new_playlist) unless new_playlist.blank?
			@history.push @song unless @song.nil?
			do_play
		end
	end

	def shuffle(params=[])
		unless params.empty?
			params.each do |param|
				@is_shuffling = param[:value] =~ /on|true|1|si|ok/
			end
		end
		display(@is_shuffling ? "Everyday i'm shuffling" : "Shuffle is off")

	end

	def next(params=[])
		if @play_index + 1 < @playlist.size
			@history.push @song unless @song.nil?

			if @is_shuffling
				@queue.push @playlist[rand(@playlist.size)]
			else
				@play_index += 1
				@queue.push @playlist[@play_index]
			end

			do_play
		else
			display "No more songs in playlist!"
		end
	end

	def prev(params=[])
		if @history.blank?
			display "Thre is no files in history"
		else
			@queue.unshift @history.pop
			@play_index -= 1 if @play_index > 0

			do_play
		end
	end

	private

	def do_play
		if @queue.blank?
			return self.next
		end

		old_song = @song
		@song = @queue.shift

		# antes de cambiar de cancion calificamos la actual rola
		@taste.calculate_weight(
			old_song,
			@song
		) unless old_song.nil?


		if @song.nil?
			display 'There is no song to play' 
			return nil
		end

		if @song.class == Artist
			@artist = @song
			return play([{type: :object, value: :artist}])
		elsif @song.class == Album
			@album = @song
			return play([{type: :object, value: :album}])
		end

		@album = @song.album 
		@artist = @song.artist

		@player.play(@song.path)

		# agregamos al contador de reproducciones
		Song.increment_counter :plays, @song.id

		display @song

		@song
	end


	def show(params=[])
		if params.blank?
			display @song
			show_progress @song 
		else
			params.each do |param|
				case param[:type]
					when :object
						case param[:value]
							when :library then @focus = obj = find_by_query
							when :artists then @focus = obj = Artist.all
							when :albums then @focus = obj = Album.all
							when /playlist|search|history/ then @focus = obj = instance_variable_get("@#{param[:value]}")
							when /artist|album/ then obj = instance_variable_get("@#{param[:value]}")
							when :recent_added then @focus = obj = Song.where('created_at > ?', Song.maximum('created_at') - (60*60*24) )
							else
								drive = @drives.find{|d| d.name.to_sym == param[:value]}
								@focus = obj = Song.where('drive_id = ?', drive.id).to_a unless drive.nil?
						end
					else
						obj = @song
				end # case
				display(obj)
			end # do
		end # if
	end

	def show_progress(song)
		actual = @song_status["mp3.position.microseconds"] / 1000000
		percentage = ((actual * 100) / song.duration) / 10
		display "#{to_time(actual)} <#{"=" * (percentage*2)}#{"-" * ((10-percentage)*2)}> #{to_time(song.duration)}"
	end

	def pause(params=[])
		@status == :PLAYING ? @player.pause : @player.resume
	end

	def connect(params=[])
		path_param = params.find{|p| p[:type] == :path}
		path_return nil unless Dir.exist?(path_param[:value])

		name_param = params.find{|p| p[:type] == :literal}
		@drives << (new_drive = Drive.create(name: name_param[:value], path: path_param[:value]))

		music_files = Dir.glob("#{path_param[:value]}/**/*.mp3")
		imported = 0
		to_be_imported = music_files.size

		music_files.each do |file_path|
			create_song_from_file(file_path, new_drive)
			imported += 1
			display "Importing #{imported}/#{to_be_imported}..."
		end

		return music_files.size
	end

	def ff(params=[])
		next_pos = @song_status["mp3.position.byte"] + (@song_status["mp3.frame.size.bytes"] * FAST_FORWARD_STEP)
		@player.seek(next_pos)
	end

	def fb(params=[])
		next_pos = @song_status["mp3.position.byte"] - (@song_status["mp3.frame.size.bytes"] * FAST_FORWARD_STEP)
		@player.seek(next_pos)
	end

	def kill(params=[])
		if get_confirmation("Are you sure you want to delete #{@song} ???")
			# detenemos la reproduccion
			self.stop

			path = Shellwords.escape("#{@song.drive.path}/#{@song.relative_path}")
			system("mv #{path} ~/tmp/#{rand()}.mp3")

			if $?.exitstatus == 0
				@song.delete
				display("Song deleted!")
			else
				display("An error occurred when deleting the song #{@song}")
			end
			
			# reanudamos la reproduccion
			self.next
		end
	end

	def repeat(params=[])
		next_pos = @song_status["mp3.position.byte"] + (@song_status["mp3.frame.size.bytes"] * FAST_FORWARD_STEP)
		@player.seek(next_pos)
	end

	private

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
			Song.all
		else
			#Song.joins("left outer join artists on artists.id == songs.artist_id")
			#.joins("left outer join albums on albums.id == songs.album_id")
			Song.joins(:artist, :album)
			.where(where_clause, *where_params)
		end
	end

	def set_playlist(songs)
		@playlist = @focus = songs
		@play_index = -1
		@queue = []
	end

	def append_to_playlist(songs)
		@playlist = @playlist + songs
	end

	def method_missing(method_name, *args)
		# interrogando sobre el estatus del reproductor
		if method_name =~ /\A(.*?)\?\Z/
			self.class.class_eval do 
			define_method method_name do
				@status.downcase == $1.to_sym
			end
			end

		send(method_name, *args)
		else
			# mandamos al player todo lo que no conozcamos
			@player.send(method_name)
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

	def display(object, continuos=false)
		text = object.to_s
		if continuos
			print text
		else
			puts text
		end
		text
	end

end

class Array
	def to_s
		idx = 0
		self.collect{|e| "#{idx += 1} #{e}" }.join("\n")
	end
end
