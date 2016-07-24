require 'spec_helper'

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }
  context 'when no playlist is active and no parameters' do
    it 'shows a message saying so, and giving instructions to play' do
      r = t.execute('show').first
      expect(r.message).to match /Nothing to show yet. Try with 'play' first./
    end
  end

  context 'with and active playlist and playback' do
    before :each do
      t.execute("connect '#{test_folder}' => test").first
      t.execute 'play'
    end

    it 'without parameters shows the current song' do
      r = t.execute('show').first
      expect(r.message).to match /.+?:::: Song: .+? (\\ Artist: .+? \\ Album: .+? )?::::.+?/
      expect(r.message).to match /.+?[\d]{2}:[\d]{2} \|[#-]+?> [\d]{2}:[\d]{2}.+?/
    end

    context 'with object parameter' do
      it 'current' do
        r = t.execute('show @current').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(3)
        expect(r.list.map{|s| s.id}).to include(1,2,3)
      end

      it 'playlist' do
        t.execute('play the for')
        r = t.execute('show @playlist').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(2)
        expect(r.list.map{|s| s.id}).to include(1,3)
      end

      it 'history' do
        t.execute('next')
        r = t.execute('show @history').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(1)
      end

      it 'queue' do
        t.execute('enqueue 2')
        r = t.execute('show @queue').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(1)
      end

      it 'focus' do
        t.execute('search the for')
        r = t.execute('show @focus').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(2)
        expect(r.list.map{|s| s.id}).to include(1,3)
      end

      it 'search' do
        t.execute('search absolution')
        r = t.execute('show @search').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(1)
        expect(r.list.map{|s| s.id}).to include(3)
      end

      it 'song' do
        r = t.execute('show @song').first
        expect(r.response_type).to eq(:message)
        expect(r).to respond_to :song
        expect(r.song).to be_instance_of Song
        expect(r.message).to match /:::: Song: .+? (\\ Artist: .+? )?(\\ Album: .+? )?::::\n?/
      end

      it 'artist' do
        r = t.execute('show @artist').first
        expect(r.response_type).to eq(:message)
        expect(r).to respond_to :artist
        expect(r.artist).to be_instance_of Artist
        expect(r.message).to match /:::: Artist: .+? ::::\n?/
      end

      it 'album' do
        r = t.execute('show @album').first
        expect(r.response_type).to eq(:message)
        expect(r).to respond_to :album
        expect(r.album).to be_instance_of Album
        expect(r.message).to match /:::: Album: .+? ::::\n?/
      end

      it 'drives' do
        r = t.execute('show @drives').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(1)
        expect(r.list.first).to be_instance_of Drive
      end

      it 'artists' do
        r = t.execute('show @artists').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(2)
        expect(r.list.map{|a| a.class}).to eq([Artist, Artist])
      end

      it 'albums' do
        r = t.execute('show @albums').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(2)
        expect(r.list.map{|a| a.class}).to eq([Album, Album])
      end

      it 'genres' do
        r = t.execute('show @genres').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(2)
        expect(r.list.map{|a| a.class}).to eq([Genre, Genre])
      end

      it 'library' do
        r = t.execute('show @library').first
        expect(r.response_type).to eq(:list)
        expect(r.list.size).to eq(3)
      end

      it 'recently_played' do
        t.execute('next').first
        r = t.execute('show @recently_played').first
        expect(r.response_type).to eq(:list)
        expect(r.list).not_to be_empty
      end

      it 'recently_added' do
        r = t.execute('show @recently_added').first
        expect(r.response_type).to eq(:list)
        expect(r.list).not_to be_empty
      end

      it 'most_played' do
        r = t.execute('show @most_played').first
        expect(r.response_type).to eq(:list)
        expect(r.list).not_to be_empty
      end

      it 'less_played' do
        r = t.execute('show @less_played').first
        expect(r.response_type).to eq(:list)
        expect(r.list).not_to be_empty
      end

      it 'populars' do
        r = t.execute('show @populars').first
        expect(r.response_type).to eq(:list)
        expect(r.list).not_to be_empty
      end
    end
  end
end
