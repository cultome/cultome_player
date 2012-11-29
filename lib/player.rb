require 'java'

absolute_file_path = File.absolute_path(__FILE__)
project_path = absolute_file_path.slice(0, absolute_file_path.rindex('/lib'))
jars_path = "#{project_path}/jars"
Dir.entries(jars_path).each{|jar| 
  if jar =~ /.jar\Z/
    puts "#{jars_path}/#{jar}"
    require "#{jars_path}/#{jar}"
  end
}

import 'Player'
import 'javazoom.jlgui.basicplayer.BasicPlayerListener'

require 'player_listener'
require 'cultome'

# iniciamos el reproductor
CultomePlayer.new.start