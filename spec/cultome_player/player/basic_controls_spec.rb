require 'spec_helper'

describe CultomePlayer::Player::BasicControls do

    COLLECTION_SIZE = 1006

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

    describe '#disconnect' do
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

        describe '#play' do
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

        describe '#prev' do
            describe 'if there is no history' do
                it 'display an alert saying "No more song in playlist"' do
                    expect{ t.prev }.to raise_error("There is no files in history")
                end
            end
        end

        describe '#next' do
            it 'display an alert saying "No more song in playlist"' do
                expect{ t.next }.to raise_error("No more songs in playlist!")
            end
        end

        describe '#play' do
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

        describe '#play' do
            it 'replace the current playlist' do
                expect{ t.play([{type: :literal, value: 'oasis'}]) }.to change{ t.current_playlist }.to( t.search([{type: :literal, value: 'oasis'}]) )
            end
        end

        describe '#next' do
            it 'change the current playback to the next in the playlist' do
                expect{ t.next }.to change{ t.current_song }
            end

            it 'update the repeat-during-shuffle lock' do
                t.should be_shuffling
                expect{ t.next }.to change{ t.send :songs_not_played_in_playlist }
            end
        end

        describe '#prev' do
            describe 'with history non-empty' do

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
        describe '#repeat' do
            it 'repeat from the beginning the current song' do
                expect { t.repeat }.to raise_error('This command is not valid in this moment.')
            end
        end

        describe '#pause' do
            it 'raise an error saying the command is not valid right now' do
                expect { t.pause }.to raise_error('This command is not valid in this moment.')
            end
        end

        describe '#ff' do
            it 'raise an error saying the command is not valid right now' do
                expect { t.ff }.to raise_error('This command is not valid in this moment.')
            end
        end

        describe '#fb' do
            it 'raise an error a message saying the command is not valid right now' do
                expect { t.fb }.to raise_error('This command is not valid in this moment.')
            end
        end

        describe '#stop' do
            it 'raise an error saying the command is not valid right now' do
                expect { t.stop }.to raise_error('This command is not valid in this moment.')
            end
        end

        describe '#shuffle' do
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

        describe '#select_play_return_value' do
            it 'return a list of songs when only one literal parameter is provided' do
                t.send(:select_play_return_value, [{type: :literal, value: 'judas'}]).should be_kind_of(Array)
            end

            it 'return a song when no parameters are provided' do
                t.send(:select_play_return_value, []).should be_kind_of(CultomePlayer::Model::Song)
            end

            it 'return a list of songs when more than one parameter is provided' do
                t.send(:select_play_return_value, [{type: :literal, value: 'lily'}, {type: :literal, value: 'oasis'}]).should be_kind_of(Array)
            end

            it 'return a song when only one number parameter is provided' do
                t.send(:select_play_return_value, [{type: :number, value: 1}]).should be_kind_of(CultomePlayer::Model::Song)
            end
        end

        describe '#pause' do
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

        describe '#ff' do
            it 'fast forward the current playback' do
                initial = t.player.song_status[:seconds]
                t.ff
                initial.should < t.player.song_status[:seconds]
            end
        end

        describe '#fb' do
            it 'fast backward the current playback' do
                initial = t.player.song_status[:seconds]
                t.fb
                initial.should > t.player.song_status[:seconds]
            end
        end

        describe '#stop' do
            it 'stop the current playback' do
                t.play unless t.playing?
                expect{ t.stop }.to change{ t.playing? }.from(true).to(false)
            end
        end
    end

    #########################################################
    ################### Utilities ###########################
    #########################################################
    describe '#create_song_from_file' do
        it 'create a song in the database with information of a mp3 file' do
            t.should_receive(:extract_mp3_information).with("/home/user/fake.mp3").and_return({
                name: "Fake Name",
                artist: "Fake Artist",
                album: "Fake Album",
                track: 99,
                duration: 125,
                year: 2014,
                genre: "Psicoledia",
            })
            CultomePlayer::Model::Artist.should_receive(:where).and_call_original
            CultomePlayer::Model::Album.should_receive(:where).and_call_original
            CultomePlayer::Model::Genre.should_receive(:where).and_call_original

            t.send(:create_song_from_file, '/home/user/fake.mp3', CultomePlayer::Model::Drive.all.first).should be_kind_of CultomePlayer::Model::Song
        end
    end

    describe '#generate_playlist' do
        it 'generate a playlist with a literal parameter' do
            playlist = t.send(:generate_playlist, [{type: :literal, value: 'oasis'}])
            playlist.should be_kind_of Array
            playlist.should_not be_empty
        end

        it 'generate a plylist with the entire library if no parameter are provided and the current playlist is empty' do
            t.current_playlist.should be_empty
            playlist = t.send(:generate_playlist, [])
            playlist.should have(COLLECTION_SIZE).items
        end
    end

    describe '#find_by_query' do
        it 'create an OR condition from criteria' do
            results = t.send(:find_by_query, {or: [
                   {id: 1, condition: '(artists.name like ?)', value: 'oasis'},
                   {id: 1, condition: '(artists.name like ?)', value: 'lily'},
            ], and: []})

            results.each{|r| r.artist.name.downcase.should match /(oasis|lily)/}
        end

        it 'create an AND condition from criteria' do
            results = t.send(:find_by_query, {or: [], and: [
                   {id: 1, condition: '(artists.name like ?)', value: 'oasis'},
                   {id: 2, condition: '(albums.name like ?)', value: 'unplugged'},
            ]})

            results.each do |r| 
                r.artist.name.downcase.should eq("oasis")
                r.album.name.downcase.should eq("mtv unplugged")
            end
        end
    end

    describe '#do_play' do
        it 'call next when the playback queue is empty' do
            t.should_receive(:next)
            t.send(:do_play)
        end

        it 'program the next song in the playback queue to be played' do
            next_song = CultomePlayer::Model::Song.all.first
            t.player.queue << next_song
            t.send(:do_play)
            t.current_song.should eq(next_song)
        end

        describe 'if the object in the playback queue is an Artist' do
            it "create a playlist with the artist's songs" do
                next_artist = CultomePlayer::Model::Artist.all.first
                t.player.queue << next_artist
                t.send(:do_play)
                t.current_playlist.each{|s| s.artist.should eq(next_artist)}
            end
        end

        describe 'if the object in the playback queue is an Album' do
            it "create a playlist with the album's songs" do
                next_album = CultomePlayer::Model::Album.all.first
                t.player.queue << next_album
                t.send(:do_play)
                t.current_playlist.each{|s| s.album.should eq(next_album)}
            end
        end

        describe 'if the object in the playback queue is an Genre' do
            it "create a playlist with songs of the genre" do
                next_genre = CultomePlayer::Model::Genre.all.last
                t.player.queue << next_genre
                t.send(:do_play)
                t.current_playlist.each{|s| s.genres.should include(next_genre)}
            end
        end
    end

    describe '#polish_mp3_info' do
        it 'clean the information in a song hash' do
            info = {
                name: "fake name",
                artist: " Fake artist ",
                album: "Fake album",
                track: '99',
                duration: '125',
                year: '2014',
                genre: "     psicoledia      ",
            }

            t.send(:polish_mp3_info, info).should eq({
                name: "Fake Name",
                artist: "Fake Artist",
                album: "Fake Album",
                track: 99,
                duration: 125,
                year: 2014,
                genre: "Psicoledia",
            })
        end
    end

    describe '#songs_not_played_in_playlist'
end
