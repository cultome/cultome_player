require 'spec_helper'

describe CultomePlayer::Player::PlayerExposer do
    let(:t){ Test.new }

    it 'respond to show command' do
        t.should respond_to(:show)
    end

    it 'consult the playing status of the player' do
        t.should_not be_playing
    end

    describe '#show' do

        before :all do
            @t = Test.new
            # con este comand llenamos la playlist,
            # y ponemos una rola a tocar
            @t.play

            # con esto metemos algo en el history
            3.times { @t.next }
        end

        it 'show the status of the current playback' do
            @t.c4("HOLA")
            @t.show.should match(/[\d]{2}\:[\d]{2} [<=\->]+ [\d]{2}\:[\d]{2}/)
        end

        it 'show the library object' do
            @t.show([{type: :object, value: :library}]).should eq( CultomePlayer::Model::Song.connected)
        end

        it 'show the artist collection' do
            @t.show([{type: :object, value: :artists}]).should eq( CultomePlayer::Model::Artist.order(:name).all)
        end

        it 'show the album collection' do
            @t.show([{type: :object, value: :albums}]).should eq( CultomePlayer::Model::Album.order(:name).all)
        end

        it 'show the genres collection' do
            @t.show([{type: :object, value: :genres}]).should eq( CultomePlayer::Model::Genre.order(:name).all)
        end

        it 'show the playlist object' do
            @t.show([{type: :object, value: :playlist}]).should eq( CultomePlayer::Model::Song.connected)
        end

        it 'show the search results' do
            @t.search([{type: :literal, value: 'judas'}])
            @t.show([{type: :object, value: :search_results}]).should eq( @t.player.search_results)
        end

        it 'show the aliased search results' do
            @t.search([{type: :literal, value: 'oasis'}])
            @t.show([{type: :object, value: :search}]).should eq(@t.player.search_results)
        end

        it 'show the history playlist' do
            @t.show([{type: :object, value: :history}]).should eq(@t.player.history)
        end

        it 'show the artist of the current song' do
            @t.show([{type: :object, value: :artist}]).should eq(@t.player.artist)
        end

        it 'show the album of the current song' do
            @t.show([{type: :object, value: :album}]).should eq(@t.player.album)
        end

        it 'show the playback queue' do
            @t.show([{type: :object, value: :queue}]).should eq(@t.player.queue)
        end

        it 'show the focus list' do
            @t.show([{type: :object, value: :focus}]).should eq(@t.player.focus)
        end

        it 'show the drives list' do
            @t.show([{type: :object, value: :drives}]).should eq(@t.drives_registered)
        end

        it 'show the recently added songs list' do
            @t.show([{type: :object, value: :recently_added}]).should eq(
                CultomePlayer::Model::Song.where('created_at > ?', CultomePlayer::Model::Song.maximum('created_at') - (60*60*24) )
            )
        end

        it 'show the songs with the genre equal to the current song' do
            @t.show([{type: :object, value: :genre}]).should eq(CultomePlayer::Model::Song.connected.joins(:genres).where('genres.name in (?)', @t.current_song.genres.collect{|g| g.name }).to_a)
        end

        it 'show the song list in a named registered drive' do
            @t.show([{type: :object, value: :d1}]).should eq(CultomePlayer::Model::Song.joins(:drive).where('songs.drive_id = drives.id and drives.name = ?', 'd1').to_a)
        end
    end
end
