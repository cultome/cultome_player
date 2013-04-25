require 'cultome/plugin'
require 'net/http'
require 'json'
require 'cgi'
require 'htmlentities'

# Plugin tha find the lyrics for the current song.
module Plugin
	class LyricFinder < PluginBase


		# Register the command: lyric
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{lyric: {help: "Find the lyric of the current song", params_format: ""}}
		end

		# Search and display the lyrics for the current song
		def lyric(params=[])
			song = @p.song.name
			artist = @p.artist.name

			display("Finding lyric for #{song}...")

			url = "http://lyrics.wikia.com/api.php?artist=#{CGI::escape(artist)}&song=#{CGI::escape(song)}&fmt=json"

			response = Net::HTTP.get_response(URI(url)).body
			json = JSON.parse(response.gsub("\n", '').gsub("'", '"').gsub('song = ', ''))
			Net::HTTP.get_response(URI(json['url'])).body.lines.each do |line|
				if line =~ /<div class='lyricbox'>/
					lyric = HTMLEntities.new.decode(line.gsub(/<div.*?>.*?<\/div>/, '').gsub(/<br.*?>/, "\n").gsub(/<.*/, ''))
					display(":::: Lyric for #{song} ::::")
					display(lyric)
					return lyric
				end
			end
		end
	end
end

