require 'user_input'

class TestUserInput
  include UserInput
end

describe TestUserInput do
  let(:parser) { TestUserInput.new }

  context '#parse' do
    context 'search' do
      it "busqueda sin parametros" do
        cmd = parser.parse 'search'
        cmd.should == [{:command=>"search", :params=>[]}]
      end

      it "buscando en artista, album o rola" do
        cmd = parser.parse 'search artista'
        cmd.should == [{:command=>"search", :params=>[{:value=>"artista", :type=>:literal}]}]
      end

      it "buscando en artista, album o rola" do
        cmd = parser.parse 'search a:artista'
        cmd.should == [{:command=>"search", :params=>[{:criteria=>:a, :value=>"artista", :type=>:criteria}]}]
      end

      it "buscando en artista, album o rola" do
        cmd = parser.parse 'search b:album'
        cmd.should == [{:command=>"search", :params=>[{:criteria=>:b, :value=>"album", :type=>:criteria}]}]
      end

      it "buscando en artista, album o rola" do
        cmd = parser.parse 'search s:rola'
        cmd.should == [{:command=>"search", :params=>[{:criteria=>:s, :value=>"rola", :type=>:criteria}]}]
      end

      it "buscando en artista, album o rola todas las palabras" do
        cmd = parser.parse 'search artista album rola'
        cmd.should == [{:command=>"search", :params=>[{:value=>"artista", :type=>:literal}, {:value=>"album", :type=>:literal}, {:value=>"rola", :type=>:literal}]}]
      end

      it "buscando en artista, album o rola todas las palabras" do
        cmd = parser.parse 'search a:artista b:album s:rola'
        cmd.should == [{:command=>"search", :params=>[{:criteria=>:a, :value=>"artista", :type=>:criteria}, {:criteria=>:b, :value=>"album", :type=>:criteria}, {:criteria=>:s, :value=>"rola", :type=>:criteria}]}]
      end

      it "buscando en artistas las palabras 'artista', 'artista2', 'artista3'" do
        cmd = parser.parse 'search a:artista1 a:artista2 a:artista3'
        cmd.should == [{:command=>"search", :params=>[{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:criteria=>:a, :value=>"artista2", :type=>:criteria}, {:criteria=>:a, :value=>"artista3", :type=>:criteria}]}]
      end

      it "buscando en artistas las palabras 'artista', 'artista2', 'artista3'" do
        cmd = parser.parse 'search a:artista1 @playlist algo'
        cmd.should == [{:command=>"search", :params=>[{:criteria=>:a, :value=>"artista1", :type=>:criteria}, {:value=>"playlist", :type=>:object}, {:value=>"algo", :type=>:literal}]}]
      end
    end

    context 'play' do
      it "toca la siguiente rola en la playlist actual" do
         cmd = parser.parse 'play'
         cmd.should == [{:command=>"play", :params=>[]}]
      end

      it "toca la rola 1 de la lista actual o de los resultados de la busqueda" do
         cmd = parser.parse 'play 1'
         cmd.should == [{:command=>"play", :params=>[{:value=>"1", :type=>:number}]}]
      end

      it "toca las rolas 1, 2 y 3 de la lista actual o de los resultados de la busqueda" do
         cmd = parser.parse 'play 1 2 3'
         cmd.should == [{:command=>"play", :params=>[{:value=>"1", :type=>:number}, {:value=>"2", :type=>:number}, {:value=>"3", :type=>:number}]}]
      end

      it "toca la primer rola de la playlist llamada 'playlist'" do
         cmd = parser.parse 'play @playlist'
         cmd.should == [{:command=>"play", :params=>[{:value=>"playlist", :type=>:object}]}]
      end

      it "convierte los resultado de la busqueda en la playlista actual" do
         cmd = parser.parse 'play @search'
         cmd.should == [{:command=>"play", :params=>[{:value=>"search", :type=>:object}]}]
      end

      it "convierte el historico en la playlista actual" do
         cmd = parser.parse 'play @history' 
         cmd.should == [{:command=>"play", :params=>[{:value=>"history", :type=>:object}]}]
      end

      it "busca las rolas del artista actual y hace una playlist" do
         cmd = parser.parse 'play @artist' 
         cmd.should == [{:command=>"play", :params=>[{:value=>"artist", :type=>:object}]}]
      end

      it "busca las rolas del album actual y hace una playlist" do
         cmd = parser.parse 'play @album' 
         cmd.should == [{:command=>"play", :params=>[{:value=>"album", :type=>:object}]}]
      end

      it "buscando en artista, album o rola" do
         cmd = parser.parse 'play artista'
         cmd.should == [{:command=>"play", :params=>[{:value=>"artista", :type=>:literal}]}]
      end

      it "buscando en artista, album o rola" do
         cmd = parser.parse 'play a:artista'
         cmd.should == [{:command=>"play", :params=>[{:criteria=>:a, :value=>"artista", :type=>:criteria}]}]
      end

      it "buscando en artista, album o rola" do
         cmd = parser.parse 'play b:album'
         cmd.should == [{:command=>"play", :params=>[{:criteria=>:b, :value=>"album", :type=>:criteria}]}]
      end

      it "buscando en artista, album o rola" do
         cmd = parser.parse 'play s:rola'
         cmd.should == [{:command=>"play", :params=>[{:criteria=>:s, :value=>"rola", :type=>:criteria}]}]
      end

      it "buscando en artista, album o rola todas las palabras" do
         cmd = parser.parse 'play artista album rola' 
         cmd.should == [{:command=>"play", :params=>[{:value=>"artista", :type=>:literal}, {:value=>"album", :type=>:literal}, {:value=>"rola", :type=>:literal}]}]
      end

      it "buscando en artista la palabra 'artista', en album 'album' y en rola 'rola'" do
         cmd = parser.parse 'play a:artista b:album s:rola' 
         cmd.should == [{:command=>"play", :params=>[{:criteria=>:a, :value=>"artista", :type=>:criteria}, {:criteria=>:b, :value=>"album", :type=>:criteria}, {:criteria=>:s, :value=>"rola", :type=>:criteria}]}]
      end
    end

    context "show" do
    end
    
    it "muestra rola actual, tiempo" do
       cmd = parser.parse 'show'
       cmd.should == [{:command=>"show", :params=>[]}]
    end

    it "muestra informacion del album actual" do
       cmd = parser.parse 'show @song'
       cmd.should == [{:command=>"show", :params=>[{:value=>"song", :type=>:object}]}]
    end

    it "muestra" do
       cmd = parser.parse 'show @playlist'
       cmd.should == [{:command=>"show", :params=>[{:value=>"playlist", :type=>:object}]}]
    end

    it "muestra el playlist de rolas que ya se tocaron" do
       cmd = parser.parse 'show @history'
       cmd.should == [{:command=>"show", :params=>[{:value=>"history", :type=>:object}]}]
    end

    it "muestra los resultado de la busqueda" do
       cmd = parser.parse 'show @search'
       cmd.should == [{:command=>"show", :params=>[{:value=>"search", :type=>:object}]}]
    end

    it "muestra informacion del album actual" do
       cmd = parser.parse 'show @album'
       cmd.should == [{:command=>"show", :params=>[{:value=>"album", :type=>:object}]}]
    end

    it "muestra informacion del artistaactual" do
       cmd = parser.parse 'show @artist'
       cmd.should == [{:command=>"show", :params=>[{:value=>"artist", :type=>:object}]}]
    end

    it "Pausar la reproduccion" do
      cmd = parser.parse 'pause'
      cmd.should == [{:command=>"pause", :params=>[]}]
    end

    it "Detener la reproduccion" do
      cmd = parser.parse 'stop'
      cmd.should == [{:command=>"stop", :params=>[]}]
    end

    it "Cambia a la siguiente rola" do
      cmd = parser.parse 'next'
      cmd.should == [{:command=>"next", :params=>[]}]
    end

    it "Cambia a la anterior rola" do
      cmd = parser.parse 'prev'
      cmd.should == [{:command=>"prev", :params=>[]}]
    end

    context "pipe" do
      it "debe ejecutar dos comandos" do # pipe
        cmd = parser.parse 'search algo | play'
        cmd.should == [{:command=>"play", :params=>[{:type=>:command, :value=>{:command=>"search", :params=>[{:value=>"algo", :type=>:literal}], :piped=>true}}]}]
      end

      it "debe ejecutar tres comandos" do # pipe
        cmd = parser.parse 'search algo | play | show @artist'
        cmd.should == [{:command=>"show", :params=>[{:value=>"artist", :type=>:object}, {:type=>:command, :value=>{:command=>"play", :params=>[{:type=>:command, :value=>{:command=>"search", :params=>[{:value=>"algo", :type=>:literal}], :piped=>true}}], :piped=>true}}]}]
      end
    end

    # it'stop @after_this'
    # it 'stop @after_next'
    # it 'stop @after_playlist'
    # it 'after_this_song play @playlist'
    # it 'after_this_playlist play @playlist'
  end
end
