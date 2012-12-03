require 'user_input'
require 'persistence'
require 'player_listener'

# TODO
#  - agregar el genero a los objetos del reproductor
#  - sacar los objetosa un lugar visible
#  - meter scopes para busquedas "rapidas" (ultimos reproducidos, mas tocados, meos tocados)

class CultomePlayer
  include UserInput
  include PlayerListener

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
    @play_index = 0
    @max_play_index = 0
    @status = :STOPPED
  end

  def start
    puts "Iniciando!" # aqui poner una frase humorisitca aleatoria
    self
  end

  def execute(user_input)
    cmds = parse(user_input)
    cmds.each do |cmd|
# puts "\n#{cmd[:command]}: #{cmd[:params].inspect}\n"
      send(cmd[:command], cmd[:params])
    end
  end

  # parameter types: literal, criteria
  def search(params=[])
    return [] if params.empty?

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

    @search = find_by_query(query).to_a
  end

  # parameter types: literal, criteria::: object, number
  def play(params=[])
    if @playlist.empty?
      set_playlist find_by_query # todas las canciones
      @artist = @playlist[0].artist unless @playlist.empty?
      @album = @playlist[0].album unless @playlist.empty?
    end

    search_criteria = []
    new_playlist = params.empty? ? @playlist : []

    params.each do |param|
      case param[:type]
        when /literal|criteria/
          search_criteria << param
        when :number
          @queue.push @playlist[param[:value].to_i - 1]
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
    new_playlist += search(search_criteria) unless search_criteria.empty?
    set_playlist(new_playlist) unless new_playlist.empty?

    do_play

  end

  def next(params=[])
    if @play_index + 1 <= @max_play_index
      @play_index += 1
      @history.push @song

      do_play
    end
  end

  def prev(params=[])
    unless @history.empty?
      @queue.unshift @history.pop

      do_play
    end
  end

  def show(params=[])
    obj = ""

    if params.empty?
      puts "#{obj = @song.to_s}"
    elsif
      params.each do |param|
        case param[:type]
          when :object 
            puts "#{obj = instance_variable_get("@#{param[:value]}").to_s}"
        end
      end
    end

    obj
  end

  def pause
    @status == :PLAYING ? do_pause : do_resume
  end

  private

  def do_play
    if @queue.empty?
      @queue << @playlist[@play_index]
    end

    @song = @queue.shift
    @album = @song.album
    @artist = @song.artist

    # @status = :PLAYING
    @player.play(@song.path)

    @song
  end

  def do_pause
    @player.pause
  end

  def do_resume
    @player.resume
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
    if where_clause.empty?
      where_clause = and_condition
    elsif !and_condition.empty?
      where_clause += " and #{and_condition}"
    end

    # preparamos los parametros
    where_params = query.values.collect{|c| c.collect{|v| v[:value] } if !c.empty? }.compact.flatten

    if where_clause.empty?
      Song.all
    else
      Song.joins("left outer join artists on artists.id == songs.artist_id")
      .joins("left outer join albums on albums.id == songs.album_id")
      .where(where_clause, *where_params)
    end
  end

  def set_playlist(songs)
    @playlist = songs
    @play_index = 0
    @max_play_index = songs.size
  end

  def append_to_playlist(songs)
    @playlist = @playlist + songs
  end

  def method_missing(method_name, *args)
    # interrogando sobre el estatus del reproductor
    if method_name =~ /\A(.*?)\?\Z/
      self.class.class_eval do 
        define_method method_name do
# puts "@@@@@@@@@@@@ method_name: #{method_name}: ====> #{@status.downcase} == #{$1.to_sym} ?? #{@status.downcase == $1.to_sym}"
          @status.downcase == $1.to_sym
        end
      end

      send(method_name, *args)
    end
  end
end

class Array
  def to_s
    idx = 0
    self.collect{|e| "#{idx += 1} #{e}" }.join("\n")
  end
end