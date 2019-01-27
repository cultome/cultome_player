
module CultomePlayer::Config

	# Get the mplayer_pipe environment configuration value.
	#
	# @return [String] The mplayer_pipe value for teh selected environment.
	def mplayer_pipe
		File.expand_path "~/.cultome_player/mpctr"
	end

	def db_file
		File.join(base_dir, "db.json")
	end

	def base_dir
		File.expand_path "~/.cultome_player"
	end
end
