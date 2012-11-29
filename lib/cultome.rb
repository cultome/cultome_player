require 'user_input'

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

    
  end
end
