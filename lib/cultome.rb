
class CultomePlayer
  def initialize
    listener = PlayerListener.new(self)
    @player = Player.new()
  end

  def start
  end
end
