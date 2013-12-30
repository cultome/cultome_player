require 'spec_helper'

describe CultomePlayer::Player::Playlist do
  let(:p){ CultomePlayer::Player::Playlist::Playlists.new }

  it 'add a new playlist' do
    p.should be_empty
    p.register(:playlist)
    p.should have(1).item
  end

  it 'raise error if trying to use a unregistered playlist' do
    expect{ p[:playlist] }.to raise_error('unknown playlist:playlist is not registered' )
  end

  context 'with a playlist registered' do
    before :each do
      p.register(:playlist)
    end

    it 'should return playlists object' do
      p[:playlist].should be_instance_of CultomePlayer::Player::Playlist::Playlists
    end

    it 'raise and error if traying to register a previous registered playlist' do
      expect{ p.register(:playlist) }.to raise_error('invalid registry:playlist already registered')
    end

    it 'get a playlist by name' do
      p[:playlist].should have(1).item
      p[:playlist].first.should_not be_nil
    end

    it 'add an element to an existing playlist' do
      p[:playlist].first.should be_empty
      p[:playlist] << "eleme"
      p[:playlist].first.should have(1).item
      p[:playlist] << "eleme"
      p[:playlist].first.should have(2).item
    end

    it 'replace the content of a playlist' do
      p[:playlist].first.should be_empty
      p[:playlist] << "eleme"
      p[:playlist] << "eleme"
      p[:playlist].first.should have(2).item
      p[:playlist] <= %w{uno dos tres cuatro}
      p[:playlist].first.should have(4).item
    end

    it 'raise an error if trying to get the next song in an empty list' do
      expect{ p[:playlist].next }.to raise_error 'playlist empty:no songs in playlists'
    end

    context 'with a full playlist' do
      before :each do
        p[:playlist] <= %w{uno dos tres cuatro}
      end

      it 'shuffle the content of the playlist' do
        p[:playlist].first.should eq %w{uno dos tres cuatro}
        p[:playlist].shuffle
        if p[:playlist].first == %w{uno dos tres cuatro}
          p[:playlist].shuffle
        end
        p[:playlist].first.should_not eq %w{uno dos tres cuatro}
      end

      it 'get an element by index' do
        p[:playlist].at(0).should eq "uno"
        p[:playlist].at(3).should eq "cuatro"
      end

      it 'order the content of the playlist' do
        p[:playlist].order
        p[:playlist].first.should eq %w{cuatro dos tres uno}
      end

      it 'updated the play index' do
        expect{ p[:playlist].next }.to change{ p[:playlist].play_index }.by(1)
      end

      it 'reset the play order when ordered' do
        p[:playlist].next
        p[:playlist].play_index.should eq 0
        p[:playlist].next
        p[:playlist].play_index.should eq 1

        p[:playlist].order

        p[:playlist].next
        p[:playlist].play_index.should eq 0
      end

      it 'reset the play order when shuffled' do
        p[:playlist].next
        p[:playlist].play_index.should eq 0
        p[:playlist].next
        p[:playlist].play_index.should eq 1

        p[:playlist].shuffle

        p[:playlist].next
        p[:playlist].play_index.should eq 0
      end

      it 'repeat the list if repeat is active' do
        p[:playlist].repeat?.should be_true
        p[:playlist].next.should eq "uno"
        p[:playlist].next
        p[:playlist].next
        p[:playlist].next.should eq "cuatro"
        p[:playlist].next.should eq "uno"
      end

      it 'raise an error if traying to retrive an ended playlist' do
        p[:playlist].repeat false
        p[:playlist].repeat?.should be_false
        p[:playlist].next.should eq "uno"
        p[:playlist].next
        p[:playlist].next
        p[:playlist].next.should eq "cuatro"
        expect{ p[:playlist].next }.to raise_error("end of playlist:no more song in the playlist")
      end

      it 'return nil if checking current song but playlist has not be played' do
        p[:playlist].current.should be_nil
      end

      it 'return the current song in playlist' do
        p[:playlist].next.should eq "uno"
        p[:playlist].current.should eq "uno"
      end

      it 'removes and return the next song from the playlist' do
        p[:playlist].should have(4).songs
        p[:playlist].remove_next.should eq "uno"
        p[:playlist].should have(3).songs
        p[:playlist].remove_next.should eq "dos"
        p[:playlist].should have(2).songs
      end

      it 'iterate over every song' do
        pl = ":"
        p[:playlist].each_song do |s|
          pl << s.to_s
        end
        pl.should eq ":unodostrescuatro"
      end
    end
  end

  context 'with multiple playlist registered' do
    before :each do
      p.register(:uno)
      p.register(:dos)
    end

    it 'get multiples playlists by name' do
      p[:uno, :dos].should have(2).item
    end

    it 'add an element to more than one existing playlists' do
      p[:uno, :dos].each{|p| p.should be_empty }
      p[:uno, :dos] << "elem"
      p[:uno, :dos].each{|p| p.should have(1).item }
    end

    it 'replace the content of more than one existing playlists' do
      p[:uno, :dos].each{|p| p.should be_empty }
      p[:uno, :dos] << "elem"
      p[:uno, :dos] << "elem"
      p[:uno, :dos].each{|p| p.should have(2).item }
      p[:uno, :dos].each{|p| p.should eq ["elem", "elem"] }
      p[:uno, :dos] <= %w{uno dos tres cuatro}
      p[:uno, :dos].each{|p| p.should have(4).item }
      p[:uno, :dos].each{|p| p.should eq %w{uno dos tres cuatro} }
    end

    it 'return elements in aparence order' do
      p.register(:tres)
      p[:uno] << "uno"
      p[:dos] << "dos"
      p[:tres] << "tres"

      p[:uno, :dos, :tres].next.should eq %w{uno dos tres}
    end

    it 'return nil if checking current song but playlist has not be played' do
      p[:uno, :dos].current.should be_nil
      p[:uno] << "uno"
      p[:uno].next
      expect{ p[:uno, :dos].current }.to raise_error "no current:no current song in one of the playlists"
    end

    it 'return the current song in playlist' do
      p[:uno] << "uno"
      p[:dos] << "tres"
      p[:uno, :dos].next.should eq ["uno", "tres"]
      p[:uno, :dos].current.should eq ["uno", "tres"]
    end

    it 'raise an error if getting the next of an empty playlist' do
      p[:uno] << "uno"
      expect{ p[:uno, :dos].next }.to raise_error 'playlist empty:no songs in one of the playlists'
    end

    it 'iterate over every song' do
      p[:uno] << "uno"
      p[:dos] << "dos"
      pl = ":"
      p.each_song do |s,idx|
        pl << "#{idx}#{s.to_s}"
      end
      pl.should eq ":1uno2dos"
    end
  end
end
