
RSpec.describe CultomePlayer::Core::Objects do
  it "gets one playlist" do
    lists = playlists(:current)
    expect(lists.size).to eq 1
  end

  it "gets two playlist" do
    lists = playlists(:current, :history)
    expect(lists.size).to eq 2
  end

  it "add songs to lists" do
    playlists(:current, :history).add 1,2

    expect(playlists(:current).songs.size).to eq 2
    expect(playlists(:history).songs.size).to eq 2
  end

  it "append songs to lists" do
    playlists(:current, :history).add 1,2
    playlists(:current, :history).add 3,4

    expect(playlists(:current).songs.size).to eq 4
    expect(playlists(:current).songs).to eq [1,2,3,4]
  end

  it "remove first songs only from selected playlists" do
    playlists(:current, :history).add 1,2
    expect(playlists(:current).shift).to eq 1

    expect(playlists(:current).songs.size).to eq 1
    expect(playlists(:history).songs.size).to eq 2
  end

  it "remove last songs only from selected playlists" do
    playlists(:current, :history).add 1,2
    expect(playlists(:current).pop).to eq 2

    expect(playlists(:current).songs.size).to eq 1
    expect(playlists(:history).songs.size).to eq 2
  end

  it "get current songs from selected playlists" do
    playlists(:current, :history).add 1,2

    expect(playlists(:current).current_song).to eq 1
    expect(playlists(:current, :history).current_song).to eq [1, 1]
  end

  it "get next song in selected playlist" do
    playlists(:current, :history).add 1,2,3

    expect(playlists(:current).next_song).to eq 2
    expect(playlists(:current, :history).next_song).to eq [3, 2]
    expect(playlists(:current, :history).current_song).to eq [3, 2]
  end

  it "get previous song in selected playlist" do
    playlists(:current, :history).add 1,2,3
    playlists(:current).next_song
    playlists(:current, :history).next_song

    expect(playlists(:current).prev_song).to eq 2
    expect(playlists(:current, :history).prev_song).to eq [1, 1]
    expect(playlists(:current, :history).current_song).to eq [1, 1]
  end

  it "cycle playlist if repeat is active" do
    playlists(:current, :history).add 1,2
    playlists(:current, :history).repeat = true

    expect(playlists(:current).current_song).to eq 1
    expect(playlists(:current).next_song).to eq 2

    expect(playlists(:current).current_song).to eq 2
    expect(playlists(:current).next_song).to eq 1

    expect(playlists(:current).current_song).to eq 1
  end

  it "return nil if no more songs in playlist" do
    playlists(:current, :history).add 1,2
    playlists(:current, :history).repeat = false

    expect(playlists(:current).current_song).to eq 1
    expect(playlists(:current).next_song).to eq 2

    expect(playlists(:current).current_song).to eq 2
    expect(playlists(:current).next_song).to eq nil

    expect(playlists(:current).current_song).to eq nil
  end

  it "check if playlists are empty" do
    expect(playlists(:current, :history)).to be_empty
    playlists(:current).add 1,2
    expect(playlists(:current, :history)).to be_empty
    playlists(:history).add 1,2
    expect(playlists(:current, :history)).not_to be_empty
  end
end
