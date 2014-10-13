require 'spec_helper'

describe CultomePlayer::Player::Playlist do
  let(:p){ CultomePlayer::Player::Playlist::Playlists.new }

  it 'add a new playlist' do
    expect(p).to be_empty
    p.register(:playlist)
    expect(p.size).to eq 1
  end

  it 'raise error if trying to use a unregistered playlist' do
    expect{ p[:playlist] }.to raise_error('unknown playlist:playlist is not registered' )
  end

  context 'with a playlist registered' do
    before :each do
      p.register(:playlist)
    end

    it 'return playlists object' do
      expect(p[:playlist]).to be_instance_of CultomePlayer::Player::Playlist::Playlists
    end

    it 'raise and error if traying to register a previous registered playlist' do
      expect{ p.register(:playlist) }.to raise_error('invalid registry:playlist already registered')
    end

    it 'get a playlist by name' do
      expect(p[:playlist].size).to eq 1
      expect(p[:playlist].first).not_to be_nil
    end

    it 'add an element to an existing playlist' do
      expect(p[:playlist].first).to be_empty
      p[:playlist] << "eleme"
      expect(p[:playlist].first.size).to eq 1
      p[:playlist] << "eleme"
      expect(p[:playlist].first.size).to eq 2
    end

    it 'replace the content of a playlist' do
      expect(p[:playlist].first).to be_empty
      p[:playlist] << "eleme"
      p[:playlist] << "eleme"
      expect(p[:playlist].first.size).to eq 2
      p[:playlist] <= %w{uno dos tres cuatro}
      expect(p[:playlist].first.size).to eq 4
    end

    it 'raise an error if trying to get the next song in an empty list' do
      expect{ p[:playlist].next }.to raise_error 'playlist empty:no songs in playlists'
    end

    it 'change shuffle status' do
      expect(p[:playlist]).not_to be_shuffling
      p[:playlist].shuffle
      expect(p[:playlist]).to be_shuffling
      p[:playlist].order
      expect(p[:playlist]).not_to be_shuffling
    end

    context 'with a full playlist' do
      before :each do
        p[:playlist] <= %w{uno dos tres cuatro}
      end

      it 'shuffle the content of the playlist' do
        expect(p[:playlist].first).to eq %w{uno dos tres cuatro}
        p[:playlist].shuffle
        p[:playlist].shuffle if p[:playlist].first == %w{uno dos tres cuatro}
        expect(p[:playlist].first).not_to eq %w{uno dos tres cuatro}
      end

      it 'get an element by index' do
        expect(p[:playlist].at(0)).to eq "uno"
        expect(p[:playlist].at(3)).to eq "cuatro"
      end

      it 'order the content of the playlist' do
        p[:playlist].order
        expect(p[:playlist].first).to eq %w{cuatro dos tres uno}
      end

      it 'updated the play index' do
        expect{ p[:playlist].next }.to change{ p[:playlist].play_index }.by(1)
      end

      it 'reset the play order when ordered' do
        p[:playlist].next
        expect(p[:playlist].play_index).to eq 0
        p[:playlist].next
        expect(p[:playlist].play_index).to eq 1

        p[:playlist].order

        p[:playlist].next
        expect(p[:playlist].play_index).to eq 0
      end

      it 'reset the play order when shuffled' do
        p[:playlist].next
        expect(p[:playlist].play_index).to eq 0
        p[:playlist].next
        expect(p[:playlist].play_index).to eq 1

        p[:playlist].shuffle

        p[:playlist].next
        expect(p[:playlist].play_index).to eq 0
      end

      it 'repeat the list if repeat is active' do
        expect(p[:playlist].repeat?).to be true
        expect(p[:playlist].next).to eq "uno"
        p[:playlist].next
        p[:playlist].next
        expect(p[:playlist].next).to eq "cuatro"
        expect(p[:playlist].next).to eq "uno"
      end

      it 'raise an error if traying to retrive an ended playlist' do
        p[:playlist].repeat false
        expect(p[:playlist].repeat?).to be false
        expect(p[:playlist].next).to eq "uno"
        p[:playlist].next
        p[:playlist].next
        expect(p[:playlist].next).to eq "cuatro"
        expect{ p[:playlist].next }.to raise_error("playlist empty:no songs in playlists")
      end

      it 'return nil if checking current song but playlist has not be played' do
        expect(p[:playlist].current).to be_nil
      end

      it 'return the current song in playlist' do
        expect(p[:playlist].next).to eq "uno"
        expect(p[:playlist].current).to eq "uno"
      end

      it 'removes and return the next song from the playlist' do
        expect(p[:playlist].songs.size).to eq 4
        expect(p[:playlist].remove_next).to eq "uno"
        expect(p[:playlist].songs.size).to eq 3
        expect(p[:playlist].remove_next).to eq "dos"
        expect(p[:playlist].songs.size).to eq 2
      end

      it 'iterate over every song' do
        pl = ":"
        p[:playlist].each_song do |s|
          pl << s.to_s
        end
        expect(pl).to eq ":unodostrescuatro"
      end

      it 'check if there are songs remaining in the playlist' do
        p[:playlist].repeat(false)
        expect(p[:playlist].repeat?).to be false
        expect(p[:playlist].next?).to be true
        p[:playlist].next
        p[:playlist].next
        p[:playlist].next
        p[:playlist].next
        expect(p[:playlist].next?).to be false
      end

      it 'pop the last element inserted' do
        expect(p[:playlist].songs.size).to eq 4
        p[:playlist] << 'cinco'
        expect(p[:playlist].songs.size).to eq 5
        expect(p[:playlist].pop).to eq 'cinco'
        expect(p[:playlist].pop).to eq 'cuatro'
        expect(p[:playlist].songs.size).to eq 3
      end

      it 'rewind the playlist' do
        expect(p[:playlist].next).to eq 'uno'
        expect(p[:playlist].next).to eq 'dos'
        expect(p[:playlist].next).to eq 'tres'
        expect(p[:playlist].next).to eq 'cuatro'
        expect(p[:playlist].current).to eq 'cuatro'
        expect(p[:playlist].rewind_by(1)).to eq 'tres'
        expect(p[:playlist].current).to eq 'tres'
        expect(p[:playlist].rewind_by(2)).to eq 'uno'
        expect(p[:playlist].current).to eq 'uno'
      end
    end
  end

  context 'with multiple playlist registered' do
    before :each do
      p.register(:uno)
      p.register(:dos)
    end

    it 'get multiples playlists by name' do
      expect(p[:uno, :dos].size).to eq 2
    end

    it 'add an element to more than one existing playlists' do
      p[:uno, :dos].each{|p| expect(p).to be_empty }
      p[:uno, :dos] << "elem"
      p[:uno, :dos].each{|p| expect(p.size).to eq 1}
    end

    it 'replace the content of more than one existing playlists' do
      p[:uno, :dos].each{|p| expect(p).to be_empty }
      p[:uno, :dos] << "elem"
      p[:uno, :dos] << "elem"
      p[:uno, :dos].each{|p| expect(p.size).to eq 2}
      p[:uno, :dos].each{|p| expect(p).to eq ["elem", "elem"] }
      p[:uno, :dos] <= %w{uno dos tres cuatro}
      p[:uno, :dos].each{|p| expect(p.size).to eq 4}
      p[:uno, :dos].each{|p| expect(p).to eq %w{uno dos tres cuatro} }
    end

    it 'return elements in aparence order' do
      p.register(:tres)
      p[:uno] << "uno"
      p[:dos] << "dos"
      p[:tres] << "tres"

      expect(p[:uno, :dos, :tres].next).to eq %w{uno dos tres}
    end

    it 'return nil if checking current song but playlist has not be played' do
      expect(p[:uno, :dos].current).to be_nil
      p[:uno] << "uno"
      p[:uno].next
      expect{ p[:uno, :dos].current }.to raise_error "no current:no current song in one of the playlists"
    end

    it 'return the current song in playlist' do
      p[:uno] << "uno"
      p[:dos] << "tres"
      expect(p[:uno, :dos].next).to eq ["uno", "tres"]
      expect(p[:uno, :dos].current).to eq ["uno", "tres"]
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
      expect(pl).to eq ":1uno2dos"
    end

    it 'check if there are songs remaining in the playlists' do
      p[:uno, :dos].repeat false
      expect(p[:uno, :dos].repeat?).to eq [false, false]
      p[:uno, :dos] << 'uno'
      p[:uno] << 'dos'
      expect(p[:uno].next?).to be true
      expect(p[:dos].next?).to be true
      expect(p[:uno, :dos].next?).to eq [true, true]
      p[:uno, :dos].next
      expect(p[:uno, :dos].next?).to eq [true, false]
    end

    it 'change shuffle status' do
      expect(p[:uno, :dos].shuffling?).to eq [false, false]
      p[:uno, :dos].shuffle
      expect(p[:uno, :dos].shuffling?).to eq [true, true]
      p[:uno, :dos].order
      expect(p[:uno, :dos].shuffling?).to eq [false, false]
    end


    it 'pop the last element inserted' do
      expect(p[:uno].songs.size).to eq 0
      expect(p[:dos].songs.size).to eq 0
      p[:uno] << 'cinco'
      p[:dos] << 'seis'
      expect(p[:uno].songs.size).to eq 1
      expect(p[:dos].songs.size).to eq 1
      expect(p[:uno, :dos].pop).to eq ['cinco', 'seis']
      expect(p[:uno].songs.size).to eq 0
      expect(p[:dos].songs.size).to eq 0
    end

    it 'rewind the playlists' do
      p[:uno] << 'uno'
      p[:uno] << 'dos'
      p[:dos] << 'tres'
      p[:dos] << 'cuatro'

      expect(p[:uno, :dos].next).to eq ['uno', 'tres']
      expect(p[:uno, :dos].next).to eq ['dos', 'cuatro']
      expect(p[:uno, :dos].current).to eq ['dos', 'cuatro']
      expect(p[:uno, :dos].rewind_by(1)).to eq ['uno', 'tres']
    end
  end
end
