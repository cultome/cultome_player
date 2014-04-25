require 'spec_helper'

describe CultomePlayer::Player::Interface::Helper do
  let(:t){ TestClass.new }

  it 'raise an error if processing a unknown object' do
    expect{ t.process_for_search([Parameter.new({type: :object, value: 'unknown'})]) }.to raise_error 'invalid search:unknown type'
  end

  it 'create a progress bar' do
    t.get_progress_bar(55, 200, 10).should eq "|##-------->"
    t.get_progress_bar(55, 100, 10).should eq "|#####----->"
    t.get_progress_bar(55, 100, 20).should eq "|###########--------->"
  end

  it 'create a progress bar with labels in both sides' do
    t.get_progress_bar_with_labels(5, 10, 10, "left", "right").should eq "left |#####-----> right"
    t.get_progress_bar_with_labels(5, 10, 10, "left").should eq "left |#####----->"
    t.get_progress_bar_with_labels(5, 10, 10, "", "right").should eq "|#####-----> right"
  end

  it 'format seconds to minutos:seconds' do
    t.format_secs(4).should eq "00:04"
    t.format_secs(75).should eq "01:15"
    t.format_secs(65).should eq "01:05"
  end

  describe '#process_object_for_search' do
    it 'returns sql criteria and values for object type artist' do
      artist = double("artist", name: "artist_name")
      t.should_receive(:current_artist).and_return(artist)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :artist})] )
      q.should eq 'artists.name = ?'
      v.should eq ["artist_name"]
    end

    it 'returns sql criteria and values for object type album' do
      album = double("album", name: "album_name")
      t.should_receive(:current_album).and_return(album)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :album})] )
      q.should eq 'albums.name = ?'
      v.should eq ["album_name"]
    end

    it 'returns sql criteria and values for object type song' do
      song = double("song", name: "song_name")
      t.should_receive(:current_song).and_return(song)

      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :song})] )
      q.should eq 'songs.name = ?'
      v.should eq ["song_name"]
    end

    it 'returns sql criteria and values for object type library' do
      q,v = t.send(:process_object_for_search, [Parameter.new({type: :object, value: :library})] )
      q.should eq 'songs.id > 0'
      v.should be_empty
    end
  end

end
