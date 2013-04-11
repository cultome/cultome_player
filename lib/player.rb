puts "Iniciando!" # aqui poner una frase humorisitca aleatoria

require 'helper'
require 'java'
require 'cultome'

include Helper

require_jars

import 'Player'

init_album_and_artist

# iniciamos el reproductor
CultomePlayer.new.start

puts "Bye!" # aqui poner una frase humorisitca aleatoria
