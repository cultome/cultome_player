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

  describe '#process_object_for_search' do
    it 'returns sql criteria and values for object type artist' do
      artist = double("artist", name: "artist_name")
      expect(t).to receive(:current_artist).and_return(artist)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :artist})] )
      expect(q).to eq 'artists.name = ?'
      expect(v).to eq ["artist_name"]
    end

    it 'returns sql criteria and values for object type album' do
      album = double("album", name: "album_name")
      expect(t).to receive(:current_album).and_return(album)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :album})] )
      expect(q).to eq 'albums.name = ?'
      expect(v).to eq ["album_name"]
    end

    it 'returns sql criteria and values for object type song' do
      song = double("song", name: "song_name")
      expect(t).to receive(:current_song).and_return(song)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :song})] )
      expect(q).to eq 'songs.name = ?'
      expect(v).to eq ["song_name"]
    end

    it 'returns sql criteria and values for object type library' do
      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :library})] )
      expect(q).to eq 'songs.id > 0'
      expect(v).to be_empty
    end
  end

end
