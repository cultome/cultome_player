require 'user_input'
require 'persistence'

# TODO
#  - agregar el genero a los objetos del reproductor
#  - sacar los objetosa un lugar visible

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

    query = []

    params.each do |param|
      case param[:type]
        when :literal
          query << {id: 1, condition: '(artists.name like ? or albums.name like ? or songs.name = ?)', value: ["%#{param[:value]}%"] * 3}
        when :criteria
          if param[:criteria] == :a then query << {id: 2, condition: 'artists.name like ?', value: "%#{param[:value]}%"}
          elsif param[:criteria] == :b then query << {id: 3, condition: 'albums.name like ?', value: "%#{param[:value]}%"}
          elsif param[:criteria] == :s then query << {id: 4, condition: 'songs.name like ?', value: "%#{param[:value]}%"} end
        when :number
        when :object
        when :unknown
      end
    end

    used_condition = []
    where_clause = query.collect{|c| 
      if c[:id] == 1 && used_condition.include?(1)
        nil
      else
        used_condition << c[:id]
        c[:condition] 
      end
    }.compact.join(' and ')

puts "===========> WHERE: #{where_clause}"
#     songs = Song.joins("left outer join artists on artists.id == songs.artist_id")
#             .joins("left outer join albums on albums.id == songs.album_id")
#             .where(where_clause, query.collect{|c| c[:value]}.flatten)
# songs.each{|s| puts " ---> " + s.title}    
  end
end
