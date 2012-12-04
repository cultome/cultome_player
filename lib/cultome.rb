require 'user_input'
require 'persistence'
require 'player_listener'
require 'helper'
require 'active_support'

# TODO
#  - agregar el genero a los objetos del reproductor
#  - sacar los objetos a un lugar visible
#  - meter scopes para busquedas "rapidas" (ultimos reproducidos, mas tocados, meos tocados)
#  - Checar como meter automaticamente la insercion de registros unknown
#  - Implementar control de volumen
#  - Amarrar las teclas de flechas a acciones
#  - Agregar los alias a TODO
#  * Shuffle and replay mode
#  - Mostrar progreso de importacion de canciones al conectar un drive
#  - Importar en segundo plano
#  - Meter visualizaciones ASCII
#  - Contar las reproducciones de cada cada
#  - Mostrar TODAS las rolas de la bibliotecas conectadas
#  - Manejar los paths con espacios y caracteres especiales  durante la importacion
# 
#
# ERRORS
#  - Manejar la situacion de que la rola no cargue correctamente
#  - Ver porque no importa todas las rolas (folder con espacios? muy anidados?)
#  - Como primera accion, el 'play absolution' toca otra cancion
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
    @progress = {}
    @focus = nil
    @drives = Drive.all.to_a
  end

  def start
    puts "Iniciando!" # aqui poner una frase humorisitca aleatoria
    @running = true

    gets # el doble prompt
    while(@running) do
      print @prompt
      execute gets.chomp
    end
  end

  def execute(user_input)
    begin
      cmds = parse(user_input)
      cmds.each do |cmd|
  # puts "\n#{cmd[:command]}: #{cmd[:params].inspect}\n"
        send(cmd[:command], cmd[:params])
      end
    rescue Exception => e
      puts e.message
      # podriamos indicar que la cancion no toca simplemente y sacarla
      send(:next)
    end
  end

  def quit(params=[])
    @running = false
    @player.stop
    puts "Bye!" # aqui poner una frase humorisitca aleatoria
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

  # parameter types: literal, criteria::: object, number
  def play(params=[])
    search_criteria = []
    new_playlist = []

    if @playlist.blank?
      new_playlist = find_by_query
      if new_playlist.blank?
        puts "No music connected yet. Try 'connect C:/my_music => music_library' first!"
        return nil
      end

      # set_playlist results # todas las canciones
      @artist = new_playlist[0].artist unless new_playlist[0].blank?
      @album = new_playlist[0].album unless new_playlist[0].blank?
    end

    params.each do |param|
      case param[:type]
        when /literal|criteria/
          search_criteria << param
        when :number
          @queue.push @focus[param[:value].to_i - 1]
        when :object
          case param[:value]
            when :playlist then new_playlist = @playlist
            when :search then new_playlist += @search
            when :history then new_playlist += @history
            when :artist then new_playlist += find_by_query({or: [{id: 5, condition: 'artists.name like ?', value: "%#{ @artist.name }%"}], and: []})
            when :album then new_playlist += find_by_query({or: [{id: 5, condition: 'albums.name like ?', value: "%#{ @album.name }%"}], and: []})
          end
      end
    end

    new_playlist += search(search_criteria) unless search_criteria.blank?

    if new_playlist.blank?
      self.next
    else
      set_playlist(new_playlist)
      do_play
    end
  end

  def show(params=[])
    if params.blank?
      display @song
      show_progress @song 
    else
      params.each do |param|
        case param[:type]
          when :object
            display (@focus = instance_variable_get("@#{param[:value]}"))
        end
      end
    end
  end

  def show_progress(song)
    actual = @progress["mp3.position.microseconds"] / 1000000
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
    music_files.each do |file_path|
      create_song_from_file(file_path, new_drive)
    end

    return music_files.size
  end

  def ff(params=[])
    next_pos = @progress["mp3.position.byte"] + (@progress["mp3.frame.size.bytes"] * FAST_FORWARD_STEP)
    @player.seek(next_pos)
  end

  def fb(params=[])
    next_pos = @progress["mp3.position.byte"] - (@progress["mp3.frame.size.bytes"] * FAST_FORWARD_STEP)
    @player.seek(next_pos)
  end

  def next(params=[])
    if @play_index + 1 < @playlist.size
      @play_index += 1

      @history.push @song unless @song.nil?

      @queue.push @playlist[@play_index]

      do_play
    else
      display "No more songs in playlist!"
    end
  end

  def prev(params=[])
    unless @history.blank?
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

    @song = @queue.shift
    @album = @song.album
    @artist = @song.artist

    @player.play(@song.path)

    display @song

    @song
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
      Song.all
    else
      Song.joins("left outer join artists on artists.id == songs.artist_id")
      .joins("left outer join albums on albums.id == songs.album_id")
      .where(where_clause, *where_params)
    end
  end

  def set_playlist(songs)
    @playlist = @focus = songs
    @play_index = -1
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

    unless info[:artist].blank?
      info[:artist_id] = Artist.find_or_create_by_name(name: info[:artist]).id
    end

    unless info[:album].blank?
      info[:album_id] = Album.find_or_create_by_name(name: info[:album]).id
    end

    info[:drive_id] = drive.id
    # puts "drive.path: #{drive.path}"
    info[:relative_path] = file_path.gsub("#{drive.path}/", '')

    # puts info.inspect
    song = Song.create(info)
    # puts song.inspect

    return song
  end

  def display(object)
    text = object.to_s
    puts text
    text
  end

end

class Array
  def to_s
    idx = 0
    self.collect{|e| "#{idx += 1} #{e}" }.join("\n")
  end
end