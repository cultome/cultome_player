require 'spec_helper'

describe CultomePlayer::Player::BasicControls do

    COLLECTION_SIZE = 1005

    let(:t){ Test.new }

    before :each do
        t.stub(:display)
    end

    it 'respond to play command' do
        t.should respond_to(:play)
    end

    it 'respond to enqueue command' do
        t.should respond_to(:enqueue)
    end

    it 'respond to search command' do
        t.should respond_to(:search)
    end

    it 'respond to pause command' do
        t.should respond_to(:pause)
    end

    it 'respond to stop command' do
        t.should respond_to(:stop)
    end

    it 'respond to next command' do
        t.should respond_to(:next)
    end

    it 'respond to prev command' do
        t.should respond_to(:prev)
    end

    it 'respond to connect command' do
        t.should respond_to(:connect)
    end

    it 'respond to disconnect command' do
        t.should respond_to(:disconnect)
    end

    it 'respond to ff command' do
        t.should respond_to(:ff)
    end

    it 'respond to fb command' do
        t.should respond_to(:fb)
    end

    it 'respond to shuffle command' do
        t.should respond_to(:shuffle)
    end

    it 'respond to repeat command' do
        t.should respond_to(:repeat)
    end

    it 'search in the library' do
        results = t.search([{type: :literal, value: 'judas'}])
        results.should be_kind_of Array
        results.should_not be_empty
    end

    it 'add the songs in a filesystem folder' do
        path = t.project_path
        song1 = "#{path}/one.mp3"
        song2 = "#{path}/two.mp3"

        CultomePlayer::Model::Drive.should_receive(:create).with(name: 'my_test', path: path).and_return(CultomePlayer::Model::Drive.new(name: 'my_test', path: path))

        Dir.should_receive(:glob).and_return([song1, song2])

        t.should_receive(:create_song_from_file).twice

        t.connect([
            {type: :path, value: path},
            {type: :literal, value: 'my_test'},
        ]).should eq(2)
    end

    it 'raise an error if tray to connect an unexistent path' do
        expect { t.connect([
            {type: :path, value: '/home/inexistent/directory/'},
            {type: :literal, value: 'my_test'},
        ]) }.to raise_error('directory doesnt exist!')
    end

    context '#disconnect' do
        before :each do
            CultomePlayer::Model::Drive.all.each{|d| d.update_attributes(connected: true) }
        end

        after :each do
            CultomePlayer::Model::Drive.all.each{|d| d.update_attributes(connected: true) }
        end

        it 'remove from connected music the named drive' do
            expect{t.disconnect([type: :literal, value: 'main'])}.to change{CultomePlayer::Model::Drive.all.all?{|d| d.connected }}.from(true).to(false)
        end

        it 'raise an error if the drive does not exist' do
            drive_name = "fake"
            expect {t.disconnect([type: :literal, value: drive_name]) }.to raise_error( "An error occured when disconnecting drive #{drive_name}. Maybe is mispelled?")
        end
    end

    #########################################################
    ############ #play empty playlist, no playback ##########
    #########################################################
    context 'empty playlist and no active playback' do
        before :each do
            t.current_playlist.should be_empty
        end

        it 'enqueue songs in the current playlist' do
            expect{ t.enqueue([{type: :literal, value: 'judas'}]) }.to change{ t.current_playlist }.by( t.search([{type: :literal, value: 'judas'}]) )
        end

        context '#play' do
            it 'play a song' do
                t.play
                t.should be_playing
            end

            it 'creates a playlist' do
                t.play
                t.current_playlist.should_not be_empty
            end

            it 'if shuffle is off, plays the first song in the playlist' do
                t.turn_shuffle :off
                t.play
                t.current_song.should eq(t.current_playlist.first)
            end

            it 'without parameters create a playlist with the entire collection' do
                t.play
                t.player.should have(COLLECTION_SIZE).songs_in_playlist
            end

            it 'with parameters, create the playlist generated with the user parameters' do
                t.play([{type: :criteria, criteria: :artist, value: 'Molotov'}])
                t.current_playlist.all?{|s| s.artist.name == 'Molotov'}
            end
        end
    end

    #########################################################
    ############ #play empty playlist, playback #############
    #########################################################
    context 'with empty playlist but with active playback' do
        before :each do
            t.current_playlist.should be_empty
        end

        context '#prev' do
            describe 'if there is no history' do
                it 'display an alert saying "No more song in playlist"' do
                    expect{ t.prev }.to raise_error("There is no files in history")
                end
            end
        end

        context '#next' do
            it 'display an alert saying "No more song in playlist"' do
                expect{ t.next }.to raise_error("No more songs in playlist!")
            end
        end

        context '#play' do
            it 'play a song' do
                t.play
                t.should be_playing
            end

            it 'creates a playlist' do
                t.play
                t.current_playlist.should_not be_empty
            end

            it 'if shuffle is off, plays the first song in the playlist' do
                t.turn_shuffle :off
                t.play
                t.current_song.should eq(t.current_playlist.first)
            end

            it 'without parameters create a playlist with the entire collection' do
                expect { t.play }.to change{ t.current_playlist.size }.to(COLLECTION_SIZE)
            end

            it 'with parameters, create the playlist generated with the user parameters' do
                t.play([{type: :criteria, criteria: :artist, value: 'Molotov'}])
                t.current_playlist.all?{|s| s.artist.name == 'Molotov'}
            end

            it 'resume playback if playback is paused' do
                t.play unless t.playing?
                expect{ t.pause }.to change{ t.paused? }.from(false).to(true)
                expect{ t.play }.to change{ t.paused? }.from(true).to(false)
            end
        end
    end

    #########################################################
    ############ #play playlist, no playback ################
    #########################################################
    context 'with non-empty playlist and active playback' do
        before :each do
            t.play([{type: :literal, value: 'judas'}])
            t.current_playlist.should_not be_empty
        end

        describe '#enqueue' do
            it 'enqueue songs in the current playlist' do
                expect{ t.enqueue([{type: :literal, value: 'oasis'}]) }.to change{ t.current_playlist }.by( t.search([{type: :literal, value: 'oasis'}]) )
            end
        end

        context '#play' do
            it 'replace the current playlist' do
                expect{ t.play([{type: :literal, value: 'oasis'}]) }.to change{ t.current_playlist }.to( t.search([{type: :literal, value: 'oasis'}]) )
            end
        end

        context '#next' do
            it 'change the current playback to the next in the playlist' do
                expect{ t.next }.to change{ t.current_song }
            end

            it 'update the repeat-during-shuffle lock' do
                t.should be_shuffling
                expect{ t.next }.to change{ t.send :song_not_played_in_playlist }
            end
        end

        context '#prev' do
            context 'with history non-empty' do

                before :each do
                    @prev_song = t.current_song
                    t.next
                end

                it 'should insert songs in history' do
                    expect { t.next }.to change{ t.player.history }.by( [ t.current_song ] )
                end

                it 'change the current playback to the prev in the playlist' do
                    expect { t.prev }.to change{ t.current_song }.to(@prev_song)
                end
            end
        end
    end

    #########################################################
    ################### ALL without playback ################
    #########################################################
    context 'without active playback' do
        context '#repeat' do
            it 'repeat from the beginning the current song' do
                expect { t.repeat }.to raise_error('This command is not valid in this moment.')
            end
        end

        context '#pause' do
            it 'raise an error saying the command is not valid right now' do
                expect { t.pause }.to raise_error('This command is not valid in this moment.')
            end
        end

        context '#ff' do
            it 'raise an error saying the command is not valid right now' do
                expect { t.ff }.to raise_error('This command is not valid in this moment.')
            end
        end

        context '#fb' do
            it 'raise an error a message saying the command is not valid right now' do
                expect { t.fb }.to raise_error('This command is not valid in this moment.')
            end
        end

        context '#stop' do
            it 'raise an error saying the command is not valid right now' do
                expect { t.stop }.to raise_error('This command is not valid in this moment.')
            end
        end

        context '#shuffle' do
            it 'turn on and off the shuffle alternatively' do
                if t.shuffling?
                    expect{ t.turn_shuffle :off }.to change{ t.shuffling? }.from(true).to(false)
                    expect{ t.turn_shuffle :on }.to change{ t.shuffling? }.from(false).to(true)
                else
                    expect{ t.turn_shuffle :on }.to change{ t.shuffling? }.from(false).to(true)
                    expect{ t.turn_shuffle :off }.to change{ t.shuffling? }.from(true).to(false)
                end
            end

            it 'toggle the state of shuffle' do
                if t.shuffling?
                    expect{ t.toggle_shuffle }.to change{ t.shuffling? }.from(true).to(false)
                    expect{ t.toggle_shuffle }.to change{ t.shuffling? }.from(false).to(true)
                else
                    expect{ t.toggle_shuffle }.to change{ t.shuffling? }.from(false).to(true)
                    expect{ t.toggle_shuffle }.to change{ t.shuffling? }.from(true).to(false)
                end
            end

            it 'raise an error if parameters are not valids' do
                expect { t.turn_shuffle :nope }.to raise_error('Invalid parameter. Only :on or :off are valids')
            end
        end
    end

    #########################################################
    ################### ALL with playback ###################
    #########################################################
    context 'with active playback' do
        before :each do
            t.play([{type: :literal, value: 'judas'}])
            t.current_playlist.should_not be_empty
        end

        context '#pause' do
            it 'if playback is playing, stop the current playback' do
                t.play unless t.playing?
                expect { t.pause }.to change{ t.playing? }.from(true).to(false)
            end

            it 'if playback is paused, resume the current playback' do
                t.play unless t.playing?
                t.pause if t.playing?

                expect{ t.pause }.to change{ t.paused? }.from(true).to(false)
            end

            it 'toggle pause' do
                t.play unless t.playing?
                expect{ t.toggle_pause }.to change{ t.paused? }.from(false).to(true)
                expect{ t.toggle_pause }.to change{ t.paused? }.from(true).to(false)
            end

            it 'turn pause on and off alternatively' do
                t.play unless t.playing?
                expect{ t.turn_pause :on }.to change{ t.paused? }.from(false).to(true)
                expect{ t.turn_pause :off }.to change{ t.paused? }.from(true).to(false)
            end

            it 'raise an error if parameters are not valids' do
                expect { t.turn_pause :yes }.to raise_error('Invalid parameter. Only :on or :off are valids' )
            end
        end

        context '#ff' do
            it 'fast forward the current playback' do
                initial = t.player.song_status[:seconds]
                t.ff
                initial.should < t.player.song_status[:seconds]
            end
        end

        context '#fb' do
            it 'fast backward the current playback' do
                initial = t.player.song_status[:seconds]
                t.fb
                initial.should > t.player.song_status[:seconds]
            end
        end

        context '#stop' do
            it 'stop the current playback' do
                t.play unless t.playing?
                expect{ t.stop }.to change{ t.playing? }.from(true).to(false)
            end
        end
    end
end
