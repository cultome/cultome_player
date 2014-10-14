require 'spec_helper'

describe CultomePlayer::Plugins::Gestures do
	let(:t){ TestClass.new }

  describe 'looking for something gesture' do
    before :each do
      4.times do
        t.send(:check_gesture, CultomePlayer::Objects::Command.new({value: 'next'}, []))
      end

      Artist.create!(id: 1, name: "Rspec Star", points: 5)
      Album.create!(id: 1, name: "Rspec Album", points: 5)
      Song.create!(id: 1, name: "RSpec Blues", artist_id: 1, album_id: 1, year: 2014, track: 1, duration: 120, drive_id: 1, relative_path: "/home/user/music", points: 5, plays: 5)
    end

    it 'detect gesture' do
      expect(t).to receive(:suggest_songs).exactly(1).times
      t.send(:check_gesture, CultomePlayer::Objects::Command.new({value: 'next'}, []))
    end

    it 'reset history after gesture' do
      expect(t).to receive(:suggest_songs).exactly(2).times
      9.times do
        t.send(:check_gesture, CultomePlayer::Objects::Command.new({value: 'next'}, []))
      end
    end

    it 'always returns a song list' do
      with_connection do

        allow(t).to receive(:select_suggestion).and_return(1)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(2)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(3)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(4)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(5)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(6)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(7)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(8)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(9)
        check_all_songs(t.send(:get_suggestions))
        allow(t).to receive(:select_suggestion).and_return(10)
        check_all_songs(t.send(:get_suggestions))
      end
    end

    it 'change the focus playlist' do
      allow(t).to receive(:select_suggestion).and_return(10)
      expect{ t.send(:check_gesture, CultomePlayer::Objects::Command.new({value: 'next'}, [])) }.to change{ t.playlists[:focus].songs }
    end

  end

  def check_all_songs(list)
    expect(list).to respond_to :each
    expect(list).not_to be_empty
    list.each{|s| expect(s).to be_instance_of Song }
  end
end
