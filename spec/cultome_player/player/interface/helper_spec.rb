require 'spec_helper'

describe CultomePlayer::Player::Interface::Helper do
  let(:t){ TestClass.new }

  it 'raise an error if processing a unknown object' do
    expect{ t.process_for_search([Parameter.new({type: :object, value: 'unknown'})]) }.to raise_error 'invalid search:unknown type'
  end

  it 'create a progress bar' do
    expect(t.get_progress_bar(55, 200, 10)).to eq "|##-------->"
    expect(t.get_progress_bar(55, 100, 10)).to eq "|#####----->"
    expect(t.get_progress_bar(55, 100, 20)).to eq "|###########--------->"
  end

  it 'create a progress bar with labels in both sides' do
    expect(t.get_progress_bar_with_labels(5, 10, 10, "left", "right")).to eq "left |#####-----> right"
    expect(t.get_progress_bar_with_labels(5, 10, 10, "left")).to eq "left |#####----->"
    expect(t.get_progress_bar_with_labels(5, 10, 10, "", "right")).to eq "|#####-----> right"
  end

  it 'format seconds to minutos:seconds' do
    expect(t.format_secs(4)).to eq "00:04"
    expect(t.format_secs(75)).to eq "01:15"
    expect(t.format_secs(65)).to eq "01:05"
  end

  describe '#play_inline?' do
    it 'should return true when all play params are numbers' do
      cmd = t.parse("play 1 2 3").first
      expect(t.play_inline? cmd).to be true
    end

    it 'should return false when not all play params are numbers' do
      cmd1 = t.parse("play @song 2 3").first
      cmd2 = t.parse("play the 2").first
      expect(t.play_inline? cmd1).to be false
      expect(t.play_inline? cmd2).to be false
    end

    it 'should return true when play param is @song' do
      cmd = t.parse("play @song").first
      expect(t.play_inline? cmd).to be true
    end

    it 'should return false when play param is anything else' do
      cmd1 = t.parse("play a:the").first
      cmd2 = t.parse("play song").first
      cmd3 = t.parse("play @library").first

      expect(t.play_inline? cmd1).to be false
      expect(t.play_inline? cmd2).to be false
      expect(t.play_inline? cmd3).to be false
    end
  end

  context 'with music in the library' do
    before :each do
      t.execute "connect '#{test_folder}' => test"
    end

    describe '#get_from_focus' do
      it 'get elements by an index (index starts in one)' do
        t.execute("play")
        cmd = t.parse("play 1 2").first

        songs = t.send(:get_from_focus, cmd.params)
        expect(songs.size).to eq 2
      end
    end

    describe '#get_from_playlists' do
      it 'get all songs in the given playlists' do
        t.execute("play && next")

        songs = t.get_from_playlists([:current, :history])
        expect(songs.size).to eq 3
      end
    end

    describe '#search_songs_with' do
      it 'get songs matching the given criteria param' do
        cmd = t.parse("play a:muse").first
        songs = t.search_songs_with(cmd)
        expect(songs.size).to eq 1
        expect(songs.first.artist.name).to match /Muse/
      end

      it 'get songs matching the given literal param' do
        cmd = t.parse("play absolution").first
        songs = t.search_songs_with(cmd)
        expect(songs.size).to eq 1
        expect(songs.first.name).to match /Absolution/
      end

      it 'get songs matching the given object param' do
        cmd = t.parse("play @less_played").first
        songs = t.search_songs_with(cmd)
        expect(songs.size).to eq 3
      end

      it 'get songs matching the given combinations of params' do
        cmd = t.parse("play @less_played absolution 3").first
        songs = t.search_songs_with(cmd)
        expect(songs.size).to eq 3
      end

      it 'does not get songs from playlists' do
        cmd = t.parse("play @current").first
        songs = t.search_songs_with(cmd)
        expect(songs).to be_empty
      end
    end

    describe '#select_songs_with' do
      it 'get songs from focus playlist using number params' do
        cmd = t.parse("play 2 3").first
        songs = t.select_songs_with(cmd)
        expect(songs.size).to eq 2
      end

      it 'get songs from playlists' do
        t.execute("play")
        cmd = t.parse("play @current").first
        songs = t.select_songs_with(cmd)
        expect(songs.size).to eq 3
      end

      it 'get songs from the library and any playlist' do
        t.execute("play")
        cmd = t.parse("play @current 2 absolution").first
        songs = t.select_songs_with(cmd)
        expect(songs.size).to eq 3
      end
    end
  end

  describe '#process_for_search' do
  end

  describe '#process_literal_for_search' do
  end

  describe '#process_criteria_for_search' do
  end

  describe '#process_object_for_search' do
    it 'return sql criteria and values object type populars' do
      today = Time.now.midnight
      last_week = today - 5.day
      play_low_limit = 50

      expect(t).to receive(:get_popular_criteria_limits).and_return([last_week, today, play_low_limit])

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :populars})] )
      expect(q).to eq 'last_played_at between ? and ? and plays >= ?'
      expect(v).to eq [last_week, today, play_low_limit]
    end

    it 'return sql criteria and values object type less_played' do
      up_count = 10
      expect(t).to receive(:get_less_played_criteria_limit).and_return(up_count)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :less_played})] )
      expect(q).to eq 'plays <= ?'
      expect(v).to eq [up_count]
    end

    it 'return sql criteria and values object type most_played' do
      low_count = 10
      expect(t).to receive(:get_most_played_criteria_limit).and_return(low_count)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :most_played})] )
      expect(q).to eq 'plays >= ?'
      expect(v).to eq [low_count]
    end

    it 'return sql criteria and values object type recently_played' do
      now = Time.now.midnight
      past = now - 1.hour
      expect(t).to receive(:get_recently_played_criteria_limit).and_return([past, now])

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :recently_played})] )
      expect(q).to eq 'last_played_at between ? and ?'
      expect(v).to eq [past, now]
    end

    it 'return sql criteria and values object type recently_added' do
      today = Time.now.midnight
      last_week = today - 1.hour
      expect(t).to receive(:get_recently_added_criteria_limit).and_return([last_week, today])

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :recently_added})] )
      expect(q).to eq 'created_at between ? and ?'
      expect(v).to eq [last_week, today]
    end

    it 'returns sql criteria and values for object type library' do
      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :library})] )
      expect(q).to eq 'songs.id > 0'
      expect(v).to be_empty
    end

    it 'returns sql criteria and values for object type album' do
      album = double("album", name: "album_name")
      expect(t).to receive(:current_album).and_return(album)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :album})] )
      expect(q).to eq 'albums.name = ?'
      expect(v).to eq ["album_name"]
    end

    it 'returns sql criteria and values for object type genre' do
      song = double("song", genres: [Genre.new({name: "Rock"}), Genre.new({name: "Pop"})])
      expect(t).to receive(:current_song).and_return(song)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :genre})] )
      expect(q).to eq 'genres.name in (?)'
      expect(v).to eq ["Rock", "Pop"]
    end

    it 'returns sql criteria and values for object type artist' do
      artist = double("artist", name: "artist_name")
      expect(t).to receive(:current_artist).and_return(artist)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :artist})] )
      expect(q).to eq 'artists.name = ?'
      expect(v).to eq ["artist_name"]
    end

    it 'returns sql criteria and values for object type song' do
      song = double("song", name: "song_name")
      expect(t).to receive(:current_song).and_return(song)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :song})] )
      expect(q).to eq 'songs.name = ?'
      expect(v).to eq ["song_name"]
    end

    it 'raise an error when object is genres' do
      expect{t.send(:process_object_for_search, [Parameter.new({type: :object, value: :genres})])}.to raise_error("invalid_search:@genres has no meaning here")
    end

    it 'raise an error when object is albums' do
      expect{t.send(:process_object_for_search, [Parameter.new({type: :object, value: :albums})])}.to raise_error("invalid_search:@albums has no meaning here")
    end

    it 'raise an error when object is artists' do
      expect{t.send(:process_object_for_search, [Parameter.new({type: :object, value: :artists})])}.to raise_error("invalid_search:@artists has no meaning here")
    end

    it 'raise an error when object is drives' do
      expect{t.send(:process_object_for_search, [Parameter.new({type: :object, value: :drives})])}.to raise_error("invalid_search:@drives has no meaning here")
    end
  end
end
