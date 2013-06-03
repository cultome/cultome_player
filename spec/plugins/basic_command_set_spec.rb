require 'spec_helper'
require 'plugins/basic_command_set'
require 'cultome_player'

describe Plugins::BasicCommandSet do

    let(:p){ Cultome::CultomePlayer.new }
    let(:library_size) { 1020 }
    let(:judas_songs) { 138 }
    let(:oasis_songs) { 75 }
    let(:fake_drive) do
        fake_drive = double("drive")
        fake_drive.stub(:update_attributes)
        fake_drive.stub(:name){'main'}
        fake_drive
    end

    context 'with empty current playlist' do
        before :each do
            p.playlist.should be_empty
        end

        it '#play should create a playlist with the entire library' do
            p.execute('play')
            p.playlist.should_not be_empty
            p.is_playing_library.should be_true
            p.playlist.size.should eq(library_size)
        end

        it '#play should create a playlist with custom player object' do
            p.execute('play @populars')
            p.playlist.should_not be_empty
        end

        it '#enqueue should create a playlist with the criteria provided' do
            p.execute('enqueue a:judas')
            p.playlist.should_not be_empty
            p.is_playing_library.should be_false
            p.playlist.size.should eq(judas_songs)
        end

        it '#next should raise error' do
            p.should_receive(:display).with('No more songs in playlist!')
            p.execute('next')
        end
    end

    context 'with non-empty current playlist' do
        before :each do
            p.execute('play a:judas')
            p.playlist.size.should eq(judas_songs)
        end

        it '#play should create a new playlist with the given criteria' do
            p.execute('play a:oasis')
            p.playlist.size.should eq(oasis_songs)
        end

        it '#enqueue should create a playlist with the criteria provided' do
            p.execute('enqueue a:oasis')
            p.playlist.size.should eq(judas_songs + oasis_songs)
        end

        it '#play should play a song without adding it to the playlist' do
            initial_song = p.song.id
            p.execute('search a:oasis')
            p.execute('play 1')
            p.song.id.should_not eq(initial_song)
            p.playlist.size.should eq(judas_songs)
        end

        it '#play should append songs in play queue' do
            p.execute('search a:oasis')
            p.execute('play 1 2 3')
            p.queue.size.should eq(2)
        end

        it '#play should change the current playlist with another playlist' do
            p.execute('search a:oasis')
            p.execute('play @search')
            p.playlist.size.should eq(oasis_songs)
        end

        it '#next should add songs to the history playlist' do
            5.times { p.execute('next') }
            p.history.size.should eq(5)
        end
    end

    context 'with history empty' do
        it '#prev should raise error' do
            p.should_receive(:display).with('There is no files in history')
            p.execute('prev')
        end
    end

    context 'without active playback' do
        let(:p2) { Cultome::CultomePlayer.new }

        before :each do
            p2.should_receive(:display).with("There is not active playback")
        end

        it '#pause should raise error' do
            p2.execute('pause')
        end

        it '#stop should raise error' do
            p2.execute('stop')
        end

        it '#ff should raise error' do
            p2.execute('ff')
        end

        it '#fb should raise error' do
            p2.execute('fb')
        end

        it '#repeat should raise error' do
            p2.execute('repeat')
        end
    end

    context 'with active playback' do
        let(:p4) {
            p = Cultome::CultomePlayer.new
            p.execute('shuffle off')
            p.execute('play')
            p
        }

        it '#pause should pause playback if playing' do
            p4.status.should eq(:PLAYING)
            p4.execute('pause')
            p4.status.should eq(:PAUSED)
        end

        it '#pause should resume playback if is paused' do
            p4.status.should eq(:PLAYING)
            p4.execute('pause')
            p4.status.should eq(:PAUSED)
            p4.execute('pause')
            p4.status.should eq(:RESUMED)
        end

        it '#stop should stop playback if playing' do
            p4.status.should eq(:PLAYING)
            p4.execute('stop')
            p4.status.should eq(:STOPPED)
        end

        it '#next should change the next song in playlist' do
            p4.song.id.should eq(1)
            p4.execute('next')
            p4.song.id.should eq(2)
            p4.execute('next')
            p4.song.id.should eq(3)
        end

        it '#prev should notify there is no songs in playlist' do
            5.times { p4.execute('next') }
            p4.song.id.should eq(6)
            p4.execute('prev')
            p4.song.id.should eq(5)
            p4.execute('prev')
            p4.song.id.should eq(4)
        end

        it '#ff should move the playback ahead by **seeker_step** frames' do
            initial = p4.song_status[:bytes]
            p4.ff
            p4.song_status[:bytes].should > initial
        end

        it '#fb should move the playback backward by **seeker_step** frames' do
            initial = p4.song_status[:bytes]
            p4.fb
            p4.song_status[:bytes].should < initial
        end

        it '#repeat should play the current playing song from the beginning' do
            p4.song_status[:bytes].should > 0
            p4.execute('repeat')
            p4.song_status[:bytes].should == 0
        end
    end

    context 'Any time' do

        it '#help should show the application help' do
            p.should_receive(:display).with(/The following commands are loaded:/)
            p.execute('help')
        end

        it '#shuffle should turn on the shuffle flag' do
            p.execute('shuffle off')
            p.is_shuffling.should be_false
            p.execute('shuffle on')
            p.is_shuffling.should be_true
        end

        it '#shuffle should turn off the shuffle flag' do
            p.execute('shuffle on')
            p.is_shuffling.should be_true
            p.execute('shuffle off')
            p.is_shuffling.should be_false
        end

        it '#search should find song in the collection' do
            p.execute('search a:oasis')
            p.search_results.size.should eq(oasis_songs)
            p.focus.size.should eq(oasis_songs)
        end

        it '#connect should add a drive and the songs in it to the library' do
            Plugins::BasicCommandSet.should_receive(:create_song_from_file)
            Cultome::Drive.should_receive(:find_by_path).and_return(nil)

            p.execute("connect #{project_path}/spec/data/to_send => rspec")
        end

        it '#connect should connect an exisiting drive' do
            Cultome::Drive.should_receive(:find_by_name).and_return(fake_drive)

            p.execute("connect rspec")
        end

        it '#connect should refresh files in existing drive' do
            Plugins::BasicCommandSet.should_receive(:create_song_from_file)
            Cultome::Drive.should_receive(:find_by_path).and_return(fake_drive)
            p.should_receive(:display).with("The drive 'main' is refering the same path. Update of 'main' is in progress.")

            p.execute("connect #{project_path}/spec/data/to_send")
        end

        it '#disconnect should set offline a drive' do
            Cultome::Drive.should_receive(:find_by_name).and_return(fake_drive)
            p.execute('disconnect main')
        end

        it '#quit should stop the playback and save configuration' do
            p.player.should_receive(:stop)
            p.should_receive(:save_configuration)
            p.execute('quit')
        end
    end
end
