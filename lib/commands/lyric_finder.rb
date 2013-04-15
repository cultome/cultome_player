require 'open-uri'
require 'json'
require 'cgi'
require 'htmlentities'

class LyricFinder
	def initialize(player)
		@p = player
	end

	def display(msg)
		@p.display(msg)
	end

	def get_command_registry
		{lyric: {help: "Find the lyric of the current song", params_format: ""}}
	end

	def lyric(params=[])
		display("Finding lyric for #{@p.song.name}...")
		response = open("http://lyrics.wikia.com/api.php?artist=#{CGI::escape(@p.artist.name)}&song=#{CGI::escape(@p.song.name)}&fmt=json").string
		json = JSON.parse(response.gsub("\n", '').gsub("'", '"').gsub('song = ', ''))

		open(json['url']).readlines.each do |line|
			if line =~ /<div class='lyricbox'>/
				lyric = HTMLEntities.new.decode(line.gsub(/<div.*?>.*?<\/div>/, '').gsub(/<br.*?>/, "\n").gsub(/<.*/, ''))
				display(":::: Lyric for #{@p.song.name} ::::")
				display(lyric)
				return 
			end
		end
	end
end

