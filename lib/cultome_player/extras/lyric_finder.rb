require 'net/http'
#require 'json'
require 'cgi'
require 'htmlentities'

module CultomePlayer::Extras
    module LyricFinder

        # Register de command lyric.
        def self.included(base)
            CultomePlayer::Player.command_registry << :lyric
            CultomePlayer::Player.command_help_registry[:lyric] = {
                help: "Find the lyric of the current song",
                params_format: "",
                usage: <<-HELP
Want to sing along with you favorite other-language-song? Ask the player to find the lyric with:
    * lyric

The lyric is searched using the lyrics.wikia.com webservice. So if the player dont find the lyrics, wouldn't it be nice if you search it and upload it to the site? Surely they appreciate it and the next other-language-singers too.

                HELP
            }
        end

        # Search and display the lyrics for the current song
        def lyric(params=[])
            raise 'no active playback' if current_song.nil?

            song_name = current_song.name
            artist_name = current_song.artist.name
            found_txt = ":::: Lyric for #{song_name} ::::"

            display("Finding lyric for #{c14(song_name)}")

            url = "http://lyrics.wikia.com/api.php?artist=#{CGI::escape(artist_name)}&song=#{CGI::escape(song_name)}&fmt=json"

            begin
                client = get_http_client

                response = client.get_response(URI(url)).body
                json = JSON.parse(response.gsub("\n", '').gsub("'", '"').gsub('song = ', ''))
                client.get_response(URI(json['url'])).body.lines.each do |line|
                    if line =~ /<div class='lyricbox'>/
                        lyric = HTMLEntities.new.decode(line.gsub(/<div.*?>.*?<\/div>/, '').gsub(/<br.*?>/, "\n").gsub(/<.*/, ''))

                        #thrd.kill
                        display c4(found_txt)

                        display c12(lyric)
                        return lyric
                    end
                end
            rescue Exception => e
                raise 'internet not available' if e.message =~ /(Connection refused|Network is unreachable|name or service not known)/
            end
        end
    end
end
