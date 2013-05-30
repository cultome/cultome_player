require 'spec_helper_basic'

=begin
def get_fake_player
	fake_similars = double("similars")
	fake_similars.stub(:create)
	fake_similars.stub(:empty?).and_return(true)

	fake_song = double("song")
	fake_song.stub(:name).and_return("Traffic Light", "Great Dj", "Up and Down")
	fake_song.stub(:id).and_return(1067, 1066, 1086)
	fake_song.stub(:path).and_return("spec/data/to_send/music.mp3")
	fake_song.stub(:similars).and_return(fake_similars)

	fake_player = double("cultome_player")
	fake_prev_song = double("prev_song")

	fake_artist = double("artist")
	fake_artist.stub(:name).and_return("The Ting Tings", "The Ting Tings", "Vengaboys")
	fake_artist.stub(:id).and_return(160, 160, 138)
	fake_artist.stub(:similars).and_return(fake_similars)

	fake_prev_song.stub(:name).and_return("Great Dj", "Up and Down", "Traffic Light")

	fake_player.stub(:song){ fake_song }
	fake_player.stub(:artist){ fake_artist }
	fake_player.stub(:prev_song){ fake_prev_song }
	fake_player.stub(:display){}
	fake_player.stub(:focus=){}
	fake_player.stub(:song_status){{
		"mp3.position.microseconds" => 30000000,
	}}
	fake_player.stub(:current_command){ {command: :next, params: []} }
	fake_player
end
=end

# definimos los metodos de los colores de tal forma que no afecten los specs
50.times do |idx|
	Cultome::Helper.class_eval do
		define_method "c#{idx}".to_sym do |str|
			return str
		end
	end
end
