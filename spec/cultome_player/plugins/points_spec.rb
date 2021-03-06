require 'spec_helper'

describe CultomePlayer::Plugins::Points do
  let(:t){ TestClass.new }

  before :each do
    t.execute "connect '#{test_folder}' => test"
  end

  it 'point a song if played complete' do
    expect(t).to receive(:current_song).at_least(1).and_return(Song.first)
    expect{ t.emit_event(:playback_finish, Song.first) }.to change{ Song.first.points }.by(1)
  end

  it 'point a song if repeated' do
    expect(t).to receive(:current_song).at_least(1).and_return(Song.first)
    expect{
      t.emit_event(:after_command_prev, Command.new({value: 'prev'}, []), t.success("ok"))
    }.to change{ Song.first.points }.by(1)
  end

  it 'point a song between 10-50% played' do
    expect(t).to receive(:current_song).at_least(1).and_return(Song.first)
    expect(t).to receive(:playback_length).at_least(1).and_return(100)
    expect(t).to receive(:playback_position).at_least(1).and_return(20)
    expect{
      t.emit_event(:before_command_next, Command.new({value: 'next'}, []), t.success("ok"))
    }.to change{ Song.first.points }.by(-1)
  end

  it 'point a song if almost played completly' do
    expect(t).to receive(:current_song).at_least(1).and_return(Song.first)
    expect(t).to receive(:playback_length).at_least(1).and_return(100)
    expect(t).to receive(:playback_position).at_least(1).and_return(90)
    expect{
      t.emit_event(:before_command_prev, Command.new({value: 'prev'}, []), t.success("ok"))
    }.to change{ Song.first.points }.by(1)
  end

  it 'punctuate more than once' do
    expect(t).to receive(:playback_position).and_return(10, 90)
    expect(t).to receive(:playback_length).twice.and_return(100)

    t.execute("play")
    curr_song = t.current_song

    Song.all.each{|s| expect(s.points).to eq 0 }
    # debe puntuar con puntos negativos 10...50
    expect{ t.execute("next") }.to change{ curr_song.points }.by(-1)
    old_points = curr_song.points # extraemos los punto de la nueva rola

    points_before = curr_song.points
    t.execute("prev")
    points_before > old_points
  end
end
