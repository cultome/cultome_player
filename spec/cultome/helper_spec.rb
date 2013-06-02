require 'spec_helper'
require 'cultome/helper'

describe Cultome::Helper do

    let(:h){ Cultome::Helper }

    context 'class methods' do
        it 'Should load the master configuration from config file' do
            h.master_config.should_not be_nil
        end

        it 'Should be a hash' do
            h.master_config.class.should eq(Hash)
        end

        it 'Should preserve changes in the master configuration' do
            h.master_config['dummy'].should be_nil
            h.master_config['dummy'] = 'test'
            h.master_config['dummy'].should eq('test')
        end

        it 'Should create a basic config file from nothing' do
            dummy_file = 'spec/data/config_dummy.yml'
            File.delete(dummy_file) if File.exist?(dummy_file)
            h.create_basic_config_file(dummy_file)
            File.exist?(dummy_file).should be_true
            h.master_config['core']['prompt'].should eq('cultome> ')
        end

        it 'Should point to the application directory inside user home' do
            h.user_dir.should match(/\A.*?\/home\/.+?\/\.cultome\Z/)
        end

        it 'Should detect the project root path' do
            h.project_path.end_with?('cultome_player').should be_true
        end

        it 'Should detect the migrations folder path' do
            h.migrations_path.end_with?('cultome_player/db/migrate').should be_true
        end

        it 'Should detect the db logs folder' do
            h.db_logs_folder_path.end_with?('cultome_player/logs').should be_true
        end

        it 'Should detect the db log file' do
            h.db_log_path.end_with?('cultome_player/logs/db.log').should be_true
        end

        it 'Should return the db adapter name' do
            if Cultome::Helper.environment['db_adapter']
                h.db_adapter.should_not be_nil
            else
                h.db_adapter.should eq('jdbcsqlite3')
            end
        end

        it 'Should return the db data file' do
            if Cultome::Helper.environment['database_file']
                h.db_file.should_not be_empty
            else
                h.db_file.end_with?('.cultome/db_cultome.dat').should be_true
            end
        end


        it 'Should define a palette of colors' do
            undefine_colors
            h.respond_to?(:c8).should be_false
            Cultome::Helper.define_color_palette
            h.respond_to?(:c8).should be_true
            undefine_colors && override_colors
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

    context 'instance methods' do
        it 'Should detect linux OS running the application' do
            module RbConfig
                Config = {'host_os' => :linux}
            end
            h.os.should eq(:linux)
        end

        it 'Should display messages' do
            h.display("message").should eq("message")
        end

        it 'Should create a context with DB access' do
            ActiveRecord::Base.remove_connection
            expect { Cultome::Song.all }.to raise_error(ActiveRecord::ConnectionNotEstablished)

            with_connection{ Cultome::Song.all.should_not be_nil }
        end
    end

    context 'Open class Fixnum' do
        it 'Should convert seconds to mm:ss' do
            71.to_time.should eq('01:11')
        end
    end

    context 'Open class Array' do
        it 'Should append a index number before the elements in the list' do
            ['Uno', 'Dos', 'Tres'].to_s.should eq("   1 Uno\n   2 Dos\n   3 Tres")
        end

        it 'Should return emptyo string on empty array' do
            [].to_s.should be_empty
        end
    end

    context 'Open class String' do
        it 'Should check if string is nil? or empty?' do
            "".should be_blank
            nil.should be_blank
        end
    end
end

