#require 'taste_analizer'
#require 'gesture_analizer'
require 'user_input'
require 'player_listener'
require 'helper'
require 'active_support'
require 'active_support/inflector'


# TODO
#  - Probar que pasa cuando la cancion no tiene informacion del album o artista
#  - Meter visualizaciones ASCII
#  - Cargar los plugins por separado
#  - Agregar 'show @genre'
#  - Agregar 'show 178' cuando haya artistas, albumnes o rolas en foco
# 
#
# ERRORS
#  - Revisar las conexiones la BD, se estan quedado colgadas. Abrirlas al hacer las consultas y cerrarlas despues.
#  - El listado de artistas debe ser de la musica conectada
#  - Cuando reconectas una unidad aparece dos veces en el listado
#

class CultomePlayer
	include UserInput
	include PlayerListener
	include Helper

	attr_accessor :playlist
	attr_accessor :search
	attr_accessor :history
	attr_accessor :queue
	attr_accessor :focus
	attr_accessor :drives

	attr_accessor :song
	attr_accessor :artist
	attr_accessor :album
	attr_accessor :running
	attr_accessor :play_index
	attr_accessor :is_playing_library
	attr_accessor :is_shuffling

	attr_reader :player
	attr_reader :status
	attr_reader :song_status
	attr_reader :current_command

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
		@song_status = {}
		@focus = nil
		@drives = Drive.all.to_a
		@last_cmds = []
		@is_shuffling = true
		@is_playing_library = false
		#@taste = TasteAnalizer.new(self)
		@current_command = nil
		#@gestures = GestureAnalizer.new
		@command_registry = Hash.new{|h,k| h[k] = []}
	end

	def load_commands
		command_help = []
		commands_path = "#{get_project_path}/lib/commands"
		Dir.entries(commands_path).each{|file|
			if file =~ /.rb\Z/
				require "#{commands_path}/#{file}"
				
				command = file.gsub('.rb', '').classify.constantize.new(self)
				registry = command.get_registry

				registry.each{|k,v|
					@command_registry[k] << command
					v[:command] = k
					command_help << v
				}
			end
		}
		# luego cargamos los comandos que provee esta clase
		@command_registry[:help] << self

		generate_help(command_help)
	end

	def start
		# cargamos los plugins
		load_commands

		@running = true

		while(@running) do
			execute get_command
		end
	end

	def execute(user_input)
		begin
			cmds = parse(user_input)
			if cmds.empty?
				cmds = @last_cmds
			else
				@last_cmds = cmds
			end

			cmds.each do |cmd|
				send_to_listeners(cmd)
			end
		rescue Exception => e
			display e.message
			# podriamos indicar que la cancion no toca simplemente y sacarla
			execute('next') unless e.message =~ /Invalid command/
		end
	end

	def send_to_listeners(cmd)
		listeners = @command_registry[cmd[:command]]
		unless listeners.nil?
			@current_command = cmd

			listeners.each{|listener|
				listener.send(cmd[:command], cmd[:params])
			}
		end
	end
	
	def generate_help(command_help)
		bigest_cmd = command_help.max{|a,b|
			"#{a[:command]} #{a[:params_format]}".length \
				<=> \
			"#{b[:command]} #{b[:params_format]}".length
		}
		offset = "#{bigest_cmd[:command]} #{bigest_cmd[:params_format]}".length
		bigger_offset = offset + 5

		@help_msg = "The following commands are loaded:\n"

		command_help.each{|map| 
			msg = "#{map[:command]} #{map[:params_format]}"
			@help_msg += "  #{msg.ljust(offset)} #{map[:help]}\n"
		}

		@help_msg += "\nThe following are the parameters types:\n"
		@help_msg += "  #{"number".ljust(offset)}A integer value. Normally limited by the focused object.\n"
		@help_msg += "  #{"literal".ljust(offset)}Any string of characters. If spaces are required, wrap the string with \" or '\n"
		@help_msg += "  #{"object".ljust(offset)}One of the playes's objects. The following are available:\n"
		@help_msg += "#{"".ljust(bigger_offset)}@playlist: The current playlist.\n"
		@help_msg += "#{"".ljust(bigger_offset)}@song: The current song playing.\n"
		@help_msg += "#{"".ljust(bigger_offset)}@artist: The artist from the current song playing.\n"
		@help_msg += "#{"".ljust(bigger_offset)}@album: The album from the current song playing.\n"
		@help_msg += "#{"".ljust(bigger_offset)}@history: The history playlist.\n"
		@help_msg += "#{"".ljust(bigger_offset)}@search: the playlist with the results of the lastest search.\n"
		@help_msg += "#{"".ljust(bigger_offset)}@library: The playlist of the complete library..\n"
		@help_msg += "  #{"criteria".ljust(offset)}A key-value pair in the format <key>:<literal>. Valid keys are:\n"
		@help_msg += "#{"".ljust(bigger_offset)}a: stand for Artist.\n"
		@help_msg += "#{"".ljust(bigger_offset)}b: stand for Album.\n"
		@help_msg += "#{"".ljust(bigger_offset)}t: stand for Title.\n"
		@help_msg += "  #{"path".ljust(offset)}A valid path inside local filesystem.\n"
	end

	def help(params=[])
		display(@help_msg)
	end

	def display(object, continuos=false)
		text = object.to_s
		if continuos
			print text
		else
			puts text
		end
		text
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
end

