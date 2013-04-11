puts "Iniciando!" # aqui poner una frase humorisitca aleatoria

require 'java'
require 'helper'

include Helper

jars_path = "#{get_project_path}/jars"
Dir.entries(jars_path).each{|jar| 
  if jar =~ /.jar\Z/
    # puts "#{jars_path}/#{jar}"
    require "#{jars_path}/#{jar}"
  end
}

import 'Player'

# abrimos algunas clases con propositos utilitarios
class Array
	def to_s
		idx = 0
		self.collect{|e| "#{idx += 1} #{e}" }.join("\n")
	end
end

class String
	def blank?
		self.nil? || self.empty?
	end
end

require 'persistence'

# checamos si estan los registros default
Album.find_or_create_by_id(id: 0, name: "unknown")
Artist.find_or_create_by_id(id: 0, name: "unknown")

require 'cultome'
# iniciamos el reproductor
CultomePlayer.new.start

puts "Bye!" # aqui poner una frase humorisitca aleatoria
