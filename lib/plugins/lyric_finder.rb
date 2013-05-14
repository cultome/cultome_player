require 'cultome/plugin'
require 'net/http'
require 'json'
require 'cgi'
require 'htmlentities'
require 'text_slider'

# Plugin tha find the lyrics for the current song.
module Plugin
	class LyricFinder < PluginBase

		include TextSlider

		# Register the command: lyric
		# @note Required method for register commands
		#
		# @return [Hash] Where the keys are symbols named after the registered command, and values are the help hash.
		def get_command_registry
			{lyric: {
				help: "Find the lyric of the current song",
				params_format: "",
				usage: <<HELP
Want to sing along with you favorite other-language-song? Ask the player to find the lyric with:
	* lyric

The lyric is searched using the lyrics.wikia.com webservice. So if the player dont find the lyrics, wouldn't it be nice if you search it and upload it to the site? Surely they appreciate it and the next other-language-singers too.

HELP
			}}
		end

		# Search and display the lyrics for the current song
		def lyric(params=[])
			song_name = @cultome.song.name
			artist_name = @cultome.artist.name
			found_txt = ":::: Lyric for #{song_name} ::::"

			thrd = roll_text(" Finding lyric for #{song_name} ", { 
				pad: '<', 
				repeat: true, 
				width: found_txt.length, 
				background: true }
			) do |text|
				display(text, true)
			end

			url = "http://lyrics.wikia.com/api.php?artist=#{CGI::escape(artist_name)}&song=#{CGI::escape(song_name)}&fmt=json"

			begin
				response = Net::HTTP.get_response(URI(url)).body
				json = JSON.parse(response.gsub("\n", '').gsub("'", '"').gsub('song = ', ''))
				Net::HTTP.get_response(URI(json['url'])).body.lines.each do |line|
					if line =~ /<div class='lyricbox'>/
						lyric = HTMLEntities.new.decode(line.gsub(/<div.*?>.*?<\/div>/, '').gsub(/<br.*?>/, "\n").gsub(/<.*/, ''))

						thrd.kill
						display(found_txt)

						display(lyric)
						return lyric
					end
				end
			ensure
				thrd.kill if thrd.stop?
			end
		end
	end
end

