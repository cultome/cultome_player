require 'spec_helper'

describe CultomePlayer::Extras::KillSong do
    let(:t){ Test.new }

    it 'respond to kill command' do
        t.should respond_to(:kill)
    end

    it 'delete a song from the filesystem' do
        t.play
        t.current_song.should_receive(:delete)
        File.should_receive(:delete)
        Readline.should_receive(:readline).and_return('yes')
        t.kill
    end

    it 'raise an error if there is no active playback' do
        expect { t.kill }.to raise_error('no active playback')
    end

end
