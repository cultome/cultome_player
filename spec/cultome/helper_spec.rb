require 'spec_helper'
require 'cultome/helper'

class Test
	include Helper
end

describe Helper do

	let(:h){ Test.new }

	it 'Should detect the project root path' do
		h.project_path.end_with?('cultome_player').should be_true
	end

	it 'Should convert seconds to mm:ss' do
		h.to_time(71).should eq('01:11')
	end

	it 'Should detect the db logs folder' do
		h.db_logs_folder_path.end_with?('cultome_player/logs').should be_true
	end

	it 'Should detect the db log file' do
		h.db_log_path.end_with?('cultome_player/logs/db.log').should be_true
	end

	it 'Should return the db adapter name' do
		if ENV['db_adapter']
			h.db_adapter.should_not be_nil
		else
			h.db_adapter.should eq('jdbcsqlite3')
		end
	end

	it 'Should return the db data file' do
		h.db_file.end_with?('.cultome/db_cultome.dat').should be_true
	end

	it 'Should detect the migrations folder path' do
		h.migrations_path.end_with?('cultome_player/db/migrate').should be_true
	end

	it 'Should require all the jars in the project', java: true do
		h.require_jars.should include("basicplayer3.0.jar", "commons-logging-api.jar", "jl1.0.jar", "kj_dsp1.1.jar", "mp3spi1.9.4.jar", "player.jar", "tritonus_share.jar")
	end

	it 'Should polish the information in the hash' do
		h.send(:polish, {
			name: " uno dos ",
			artist: " tres     ",
			album: "CUATRO CInCO    ",
			track: "6",
			year: '7',
			duration: '8'
		}).should eq({
			name: "Uno Dos",
			artist: "Tres",
			album: "Cuatro Cinco",
			track: 6,
			year: 7,
			duration: 8
		})
	end

	it 'Should extract the information from the mp3 file', resources: true do
		h.extract_mp3_information('/home/csoria/music/Gorillaz/Gorillaz/02. 5-4.mp3').should eq({
			album: "Gorillaz",
			artist: "Gorillaz",
			duration: 160,
			genre: "Pop",
			name: "5 4",
			track: 2,
			year: 1998
		})
	end
end

