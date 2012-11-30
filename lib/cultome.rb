require 'user_input'
require 'persistence'

# TODO
#  - agregar el genero a los objetos del reproductor
#  - sacar los objetosa un lugar visible
#  - meter scopes para busquedas "rapidas" (ultimos reproducidos, mas tocados, meos tocados)

class CultomePlayer
  include UserInput

  def initialize
    listener = PlayerListener.new(self)
    @player = Player.new(listener)
  end

  def start
    puts "Iniciando!" # aqui poner una frase humorisitca aleatoria
  end

  def execute(user_input)
    cmds = parse(user_input)
    cmds.each do |cmd|
      send(cmd[:command], cmd[:params])
    end
  end

  def search(params)
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
        when :number
        when :object
        when :unknown
      end
    end

    find_by_query(query)
  end

  private 

  def find_by_query(query)
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

# puts "===========> WHERE: #{where_clause}\n===========> PARAMS: #{where_params}"

    songs = Song.joins("left outer join artists on artists.id == songs.artist_id")
            .joins("left outer join albums on albums.id == songs.album_id")
            .where(where_clause, *where_params)
# puts "@@@@@@@@ songs.size: #{songs.size}"
# songs.each{|s| puts " ---> name: #{s.name}"}
  end
end
