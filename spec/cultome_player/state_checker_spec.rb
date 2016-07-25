require 'spec_helper'

describe CultomePlayer::StateChecker do
  let(:t){ TestClass.new }

  before :each do
    t.execute "connect '#{test_folder}' => test"
    t.execute("play")
  end

  it 'checks pause state' do
    expect(t.paused?).to be false
  end

	it 'checks stopped state' do
    expect(t.stopped?).to be true
  end

	it 'checks playing state' do
    expect(t.playing?).to be true
  end

	it 'checks shuffling state' do
    expect(t.shuffling?).to be true
  end

	it 'checks current_song' do
    expect(t.current_song).to be_instance_of Song
  end

	it 'checks current_artist' do
    expect(t.current_artist).to be_instance_of Artist
  end

	it 'checks current_album' do
    expect(t.current_album).to be_instance_of Album
  end

	it 'checks current_playlist' do
    expect(t.current_playlist).to be_instance_of CultomePlayer::Player::Playlist::Playlists
  end

	it 'checks playback_position' do
    expect(t.playback_position >= 0).to be true
  end

	it 'checks playback_length' do
    expect(t.playback_length >= 0).to be true
  end
end
