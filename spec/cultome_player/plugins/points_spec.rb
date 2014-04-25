require 'spec_helper'

describe CultomePlayer::Plugins::Points do
	let(:t){ TestClass.new }

  before :each do
    t.execute "connect '#{test_folder}' => test"
  end

	it 'point a song if played complete' do
		expect{ t.emit_event(:playback_finish, Song.first) }.to change{ Song.first.points }.by(1)
	end

	it 'point a song if repeated'
	it 'point a song if half played'
	it 'point a song if barely played'
end