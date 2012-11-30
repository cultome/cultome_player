require 'spec_helper'
require 'cultome'

class PlayerListener
end

class Player
end

describe CultomePlayer do

  let(:player) { CultomePlayer.new }
  before {
    Player.stub(:new)
    PlayerListener.stub(:new)
  }

  context '#execute' do
    it 'search' do
      player.should_receive(:search)
      player.execute('search')
    end

    it 'search artista' do
      player.should_receive(:search).with([{:value=>"artista", :type=>:literal}])
      player.execute('search artista')
    end

    it 'search a:artista' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista", :type=>:criteria}])
      player.execute('search a:artista')
    end

    it 'search b:album' do
      player.should_receive(:search).with([{:criteria=>:b, :value=>"album", :type=>:criteria}])
      player.execute('search b:album')
    end

    it 'search s:rola' do
      player.should_receive(:search).with([{:criteria=>:s, :value=>"rola", :type=>:criteria}])
      player.execute('search s:rola')
    end

    it 'search artista album rola' do
      player.should_receive(:search).with([{:value=>"artista", :type=>:literal}, {:value=>"album", :type=>:literal}, {:value=>"rola", :type=>:literal}])
      player.execute('search artista album rola')
    end

    it 'search a:artista b:album s:rola' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista", :type=>:criteria}, {:criteria=>:b, :value=>"album", :type=>:criteria}, {:criteria=>:s, :value=>"rola", :type=>:criteria}])
      player.execute('search a:artista b:album s:rola')
    end

    it 'search a:artista1 a:artista2 a:artista3' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:criteria=>:a, :value=>"artista2", :type=>:criteria}, {:criteria=>:a, :value=>"artista3", :type=>:criteria}])
      player.execute('search a:artista1 a:artista2 a:artista3')
    end

    it 'search a:artista1 @playlist algo' do
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:value=>:playlist, :type=>:object}, {:value=>"algo", :type=>:literal}])
      player.execute('search a:artista1 @playlist algo')
    end

    it 'play' do
      player.should_receive(:play)
      player.execute('play')
    end

    it 'play 1' do
      player.should_receive(:play).with([{:value=>"1", :type=>:number}])
      player.execute('play 1')
    end

    it 'play 1 2 3' do
      player.should_receive(:play).with([{:value=>"1", :type=>:number}, {:value=>"2", :type=>:number}, {:value=>"3", :type=>:number}])
      player.execute('play 1 2 3')
    end

    it 'play @playlist' do
      player.should_receive(:play).with([{:value=>:playlist, :type=>:object}])
      player.execute('play @playlist')
    end

    it 'play @search' do
      player.should_receive(:play).with([{:value=>:search, :type=>:object}])
      player.execute('play @search')
    end

    it 'play @history'  do
      player.should_receive(:play).with([{:value=>:history, :type=>:object}])
      player.execute('play @history')
    end

    it 'play @artist'  do
      player.should_receive(:play).with([{:value=>:artist, :type=>:object}])
      player.execute('play @artist')
    end

    it 'play @album'  do
      player.should_receive(:play).with([{:value=>:album, :type=>:object}])
      player.execute('play @album')
    end

    it 'play artista' do
      player.should_receive(:play).with([{:value=>"artista", :type=>:literal}])
      player.execute('play artista')
    end

    it 'play a:artista' do
      player.should_receive(:play).with([{:criteria=>:a, :value=>"artista", :type=>:criteria}])
      player.execute('play a:artista')
    end

    it 'play b:album' do
      player.should_receive(:play).with([{:criteria=>:b, :value=>"album", :type=>:criteria}])
      player.execute('play b:album')
    end

    it 'play s:rola' do
      player.should_receive(:play).with([{:criteria=>:s, :value=>"rola", :type=>:criteria}])
      player.execute('play s:rola')
    end

    it 'play artista album rola'  do
      player.should_receive(:play).with([{:value=>"artista", :type=>:literal}, {:value=>"album", :type=>:literal}, {:value=>"rola", :type=>:literal}])
      player.execute('play artista album rola')
    end

    it 'play a:artista b:album s:rola'  do
      player.should_receive(:play).with([{:criteria=>:a, :value=>"artista", :type=>:criteria}, {:criteria=>:b, :value=>"album", :type=>:criteria}, {:criteria=>:s, :value=>"rola", :type=>:criteria}])
      player.execute('play a:artista b:album s:rola')
    end

    it 'show' do
      player.should_receive(:show)
      player.execute('show')
    end

    it 'show @song' do
      player.should_receive(:show).with([{:value=>:song, :type=>:object}])
      player.execute('show @song')
    end

    it 'show @playlist' do
      player.should_receive(:show).with([{:value=>:playlist, :type=>:object}])
      player.execute('show @playlist')
    end

    it 'show @history' do
      player.should_receive(:show).with([{:value=>:history, :type=>:object}])
      player.execute('show @history')
    end

    it 'show @search' do
      player.should_receive(:show).with([{:value=>:search, :type=>:object}])
      player.execute('show @search')
    end

    it 'show @album' do
      player.should_receive(:show).with([{:value=>:album, :type=>:object}])
      player.execute('show @album')
    end

    it 'show @artist' do
      player.should_receive(:show).with([{:value=>:artist, :type=>:object}])
      player.execute('show @artist')
    end

  end

  context '#search' do

    before{
      @s1 = Song.find(1) # name: "If a Had A Gun", artist_id: 1, album_id: 1
      @s2 = Song.find(2) # name: "The Death of You And Me", artist_id: 1, album_id: 1
      @s3 = Song.find(3) # name: "Paranoid", artist_id: 2, album_id: 2
      @s4 = Song.find(4) # name: "Stand By Me", artist_id: 3, album_id: 3
      @s5 = Song.find(5) # name: "Destination Calabria", artist_id: 0, album_id: 0
    }
    
    it 'no_args()' do
      r = player.search
      r.should == []
    end

    it 'artista' do
      r = player.search([{:value=>"Noel", :type=>:literal}])
      r.should == [@s1, @s2]
    end

    it 'a:artista' do
      r = player.search([{:criteria=>:a, :value=>"Black", :type=>:criteria}])
      r.should == [@s3]
    end

    it 'b:album' do
      r = player.search([{:criteria=>:b, :value=>"paranoid", :type=>:criteria}])
      r.should == [@s3]
    end

    it 's:rola' do
      r = player.search([{:criteria=>:s, :value=>"Stand", :type=>:criteria}])
      r.should == [@s4]
    end

    it 'artista album rola' do
      r = player.search([{:value=>"Noel", :type=>:literal}, {:value=>"paranoid", :type=>:literal}, {:value=>"Calabria", :type=>:literal}])
      r.should == [@s1, @s2, @s3, @s5]
    end

    it 'a:artista b:album s:rola' do
      r = player.search([{:criteria=>:a, :value=>"Noel", :type=>:criteria}, {:criteria=>:b, :value=>"High", :type=>:criteria}, {:criteria=>:s, :value=>"Death", :type=>:criteria}])
      r.should == [@s2]
    end

    it 'a:artista1 a:artista2 a:artista3' do
      r = player.search([{:criteria=>:a, :value=>"Noel", :type=>:criteria}, {:criteria=>:a, :value=>"Black", :type=>:criteria}, {:criteria=>:a, :value=>"oasis", :type=>:criteria}])
      r.should == [@s1, @s2, @s3, @s4]
    end
  end

  context "#play" do
    before{
      @s1 = Song.find(1) # name: "If a Had A Gun", artist_id: 1, album_id: 1
      @s2 = Song.find(2) # name: "The Death of You And Me", artist_id: 1, album_id: 1
      @s3 = Song.find(3) # name: "Paranoid", artist_id: 2, album_id: 2
      @s4 = Song.find(4) # name: "Stand By Me", artist_id: 3, album_id: 3
      @s5 = Song.find(5) # name: "Destination Calabria", artist_id: 0, album_id: 0
    }

    context "sin playlist seleccionada" do
      before { player.playlist.should == []}
      after { player.playlist.should == [@s1, @s2, @s3, @s4, @s5] }

      it 'no args()' do
        player.play
        player.song.should == @s1
      end

      it '2' do
        player.play([{:value=>"2", :type=>:number}])
        player.song.should == @s2
      end

      it '3 4 5' do
        player.play([{:value=>"3", :type=>:number}, {:value=>"4", :type=>:number}, {:value=>"5", :type=>:number}])
        player.song.should == @s3
        player.queue.should == [@s4, @s5]
      end
    end

    context "usando objetos" do
      before { player.playlist.should == []}

      it '@playlist' do
        player.play([{:value=>:playlist, :type=>:object}])
        player.playlist.should == [@s1, @s2, @s3, @s4, @s5]
      end

      it '@search' do
        player.play
        player.search([{:value=>"Noel", :type=>:literal}])
        player.play([{:value=>:search, :type=>:object}])
        player.playlist.should == [@s1, @s2]
      end

      it '@history' do
        player.play([{:value=>"3", :type=>:number}, {:value=>"4", :type=>:number}, {:value=>"5", :type=>:number}])
        player.next
        player.next
        player.song.should == @s5
        player.play([{:value=>:history, :type=>:object}])
        player.playlist.should == [@s3, @s4]
      end

      it '@artist' do
        player.play([{:value=>:artist, :type=>:object}])
        player.playlist.should == [@s1, @s2]
      end

      it '@album' do
        player.play([{:value=>:album, :type=>:object}])
        player.playlist.should == [@s1, @s2]
      end
    end

    context "el resultado de una busqueda" do
      it 'artista' do
        player.play([{:value=>"Black", :type=>:literal}])
        player.playlist.should == [@s3]
      end

      it 'a:artista' do
        player.play([{:criteria=>:a, :value=>"Oasis", :type=>:criteria}])
        player.playlist.should == [@s4]
      end

      it 'b:album' do
        player.play([{:criteria=>:b, :value=>"Paranoid", :type=>:criteria}])
        player.playlist.should == [@s3]
      end

      it 's:rola' do
        player.play([{:criteria=>:s, :value=>"Calabria", :type=>:criteria}])
        player.playlist.should == [@s5]
      end

      it 'artista album rola'  do
        player.play([{:value=>"Noel", :type=>:literal}, {:value=>"high", :type=>:literal}, {:value=>"death", :type=>:literal}])
        player.playlist.should == [@s1, @s2]
      end

      it 'a:artista b:album s:rola'  do
        player.play([{:criteria=>:a, :value=>"Noel", :type=>:criteria}, {:criteria=>:b, :value=>"high", :type=>:criteria}, {:criteria=>:s, :value=>"death", :type=>:criteria}])
        player.playlist.should == [@s2]
      end
    end
  end

  context "#show" do
    before { player.play }

    it 'no_args()' do
      r = player.show
      r.should ==  ":::: Song: If a Had A Gun \\ Artist: Noel Gallagher ::::"
    end

    it '@song' do
      r = player.show([{:value=>:song, :type=>:object}])
      r.should == ":::: Song: If a Had A Gun \\ Artist: Noel Gallagher ::::"
    end

    it '@playlist' do
      r = player.show([{:value=>:playlist, :type=>:object}])
      r.should == "1 :::: Song: If a Had A Gun \\ Artist: Noel Gallagher ::::\n2 :::: Song: The Death of You And Me \\ Artist: Noel Gallagher ::::\n3 :::: Song: Paranoid \\ Artist: Black Sabbath ::::\n4 :::: Song: Stand By Me \\ Artist: Oasis ::::\n5 :::: Song: Destination Calabria \\ Artist: unknown ::::"
    end

    it '@history' do
      player.play([{:value=>"3", :type=>:number}, {:value=>"4", :type=>:number}, {:value=>"5", :type=>:number}])
      player.next
      player.next
      r = player.show([{:value=>:history, :type=>:object}])
      r.should == "1 :::: Song: Paranoid \\ Artist: Black Sabbath ::::\n2 :::: Song: Stand By Me \\ Artist: Oasis ::::"
    end

    it '@search' do
      player.play([{:criteria=>:b, :value=>"Paranoid", :type=>:criteria}])
      r = player.show([{:value=>:search, :type=>:object}])
      r.should == "1 :::: Song: Paranoid \\ Artist: Black Sabbath ::::"
    end

    it '@album' do
      r = player.show([{:value=>:album, :type=>:object}])
      r.should ==  ":::: Album: High Flying Birds \\ Artist: Noel Gallagher ::::"
    end

    it '@artist' do
      r = player.show([{:value=>:artist, :type=>:object}])
      r.should == ":::: Artist: Noel Gallagher ::::"
    end
  end
end

# 'pause'
# 'stop'
# 'next'
# 'prev'
# 'search algo | play'
# 'search algo | play | show @artist'