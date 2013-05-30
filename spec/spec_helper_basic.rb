require 'coveralls'

Coveralls.wear!

RSpec.configure do |config|
	config.treat_symbols_as_metadata_keys_with_true_values = true
	config.run_all_when_everything_filtered = true
	config.filter_run :focus
	config.filter_run_excluding :java, :resources

	# Run specs in random order to surface order dependencies. If you find an
	# order dependency and want to debug it, you can fix the order by providing
	# the seed, which is printed after each run.
	#     --seed 1234
	config.order = 'random'
end

# seteamos el ambiente para pruebas
ENV['db_adapter'] = 'sqlite3'
ENV['environment'] = 'dev'

require 'cultome_player'
Cultome::CultomePlayer.class_eval do
    class Player
        def initialize(player)
        end

        def play(song)
            song
        end
    end
end

require 'cultome/helper'
include Cultome::Helper

Cultome::Helper.module_eval do
    alias :display_old :display

    def display(msg, cont=false)
        msg
    end
end
