require 'spec_helper'

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }
  context 'when no playlist is active and no parameters' do
    it 'shows a message saying so, and giving instructions to play' do
      r = t.execute('show').first
      expect(r.message).to match /Nothing to show yet. Try with 'play' first./
    end
  end

  context 'with and active playlist and playback' do
    before :each do
      t.execute("connect '#{test_folder}' => test").first
      t.execute 'play'
    end

    it 'without parameters shows the current song' do
      r = t.execute('show').first
      expect(r.message).to match /.+?:::: Song: .+? (\\ Artist: .+? \\ Album: .+? )?::::.+?/
      expect(r.message).to match /.+?[\d]{2}:[\d]{2} \|[#-]+?> [\d]{2}:[\d]{2}.+?/
    end

    context 'with object parameter' do
      it 'library' do
        r = t.execute('show @library').first
        expect(r.list).not_to be_empty
      end

      it 'song' do
        r = t.execute('show @song').first
        expect(r.message).to match /:::: Song: .+? (\\ Artist: .+? )?(\\ Album: .+? )?::::\n?/
      end
    end
  end
end
