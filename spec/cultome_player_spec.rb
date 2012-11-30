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
      player.should_receive(:search).with([])
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
      player.should_receive(:search).with([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:value=>"playlist", :type=>:object}, {:value=>"algo", :type=>:literal}])
      player.execute('search a:artista1 @playlist algo')
    end
  end

  context '#search' do
    before { require 'load_fixtures' }
    
    it 'no_args()' do
      r = player.search([])
      r.should == []
    end

    it 'artista' do
      r = player.search([{:value=>"artista", :type=>:literal}])
      r.should == []
    end

    it 'a:artista' do
      r = player.search([{:criteria=>:a, :value=>"artista", :type=>:criteria}])
      r.should == []
    end

    it 'b:album' do
      r = player.search([{:criteria=>:b, :value=>"album", :type=>:criteria}])
      r.should == []
    end

    it 's:rola' do
      r = player.search([{:criteria=>:s, :value=>"rola", :type=>:criteria}])
      r.should == []
    end

    it 'artista album rola' do
      r = player.search([{:value=>"artista", :type=>:literal}, {:value=>"album", :type=>:literal}, {:value=>"rola", :type=>:literal}])
      r.should == []
    end

    it 'a:artista b:album s:rola' do
      r = player.search([{:criteria=>:a, :value=>"artista", :type=>:criteria}, {:criteria=>:b, :value=>"album", :type=>:criteria}, {:criteria=>:s, :value=>"rola", :type=>:criteria}])
      r.should == []
    end

    it 'a:artista1 a:artista2 a:artista3' do
      r = player.search([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:criteria=>:a, :value=>"artista2", :type=>:criteria}, {:criteria=>:a, :value=>"artista3", :type=>:criteria}])
      r.should == []
    end

    it 'a:artista1 @playlist algo' do
      r = player.search([{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:value=>"playlist", :type=>:object}, {:value=>"algo", :type=>:literal}])
      r.should == []
    end
  end


end

# 'play'
# 'play 1'
# 'play 1 2 3'
# 'play @playlist'
# 'play @search'
# 'play @history' 
# 'play @artist' 
# 'play @album' 
# 'play artista'
# 'play a:artista'
# 'play b:album'
# 'play s:rola'
# 'play artista album rola' 
# 'play a:artista b:album s:rola' 
# 'show'
# 'show @song'
# 'show @playlist'
# 'show @history'
# 'show @search'
# 'show @album'
# 'show @artist'
# 'pause'
# 'stop'
# 'next'
# 'prev'
# 'search algo | play'
# 'search algo | play | show @artist'