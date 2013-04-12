puts "Iniciando!" # aqui poner una frase humorisitca aleatoria

require 'helper'
require 'java'
require 'cultome'

include Helper

require_jars

import 'Player'

# iniciamos el reproductor
CultomePlayer.new.start

puts "Bye!" # aqui poner una frase humorisitca aleatoria
