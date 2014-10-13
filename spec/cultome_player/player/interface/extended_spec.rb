require 'spec_helper'

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }

  it 'repeats a song from the beginning' do
  	expect(t).to receive(:send_to_player).with(/^jump 0$/)
  	t.repeat(nil)
  end

	describe 'search' do
    it 'respond to description_search' do
      expect(t).to respond_to(:description_search)
    end

    it 'respond to usage_search' do
      expect(t).to respond_to(:usage_search)
    end

    it 'respond with Response object' do
      expect(t.execute("search on").first).to be_instance_of Response
    end
	end

	describe 'show' do
    it 'respond to description_show' do
      expect(t).to respond_to(:description_show)
    end

    it 'respond to usage_show' do
      expect(t).to respond_to(:usage_show)
    end

    it 'respond with Response object' do
      expect(t.execute("show").first).to be_instance_of Response
    end
	end

	describe 'enqueue' do
    it 'respond to description_enqueue' do
      expect(t).to respond_to(:description_enqueue)
    end

    it 'respond to usage_enqueue' do
      expect(t).to respond_to(:usage_enqueue)
    end

    it 'respond with Response object' do
      expect(t.execute("enqueue on").first).to be_instance_of Response
    end
	end

	describe 'shuffle' do
    it 'respond to description_shuffle' do
      expect(t).to respond_to(:description_shuffle)
    end

    it 'respond to usage_shuffle' do
      expect(t).to respond_to(:usage_shuffle)
    end

    it 'respond with Response object' do
      expect(t.execute("shuffle on").first).to be_instance_of Response
    end
	end

	describe 'connect' do
    it 'respond to description_connect' do
      expect(t).to respond_to(:description_connect)
    end

    it 'respond to usage_connect' do
      expect(t).to respond_to(:usage_connect)
    end

    it 'respond with Response object' do
      expect(t.execute("connect drive").first).to be_instance_of Response
    end
	end

	describe 'disconnect' do
    it 'respond to description_disconnect' do
      expect(t).to respond_to(:description_disconnect)
    end

    it 'respond to usage_disconnect' do
      expect(t).to respond_to(:usage_disconnect)
    end

    it 'respond with Response object' do
      expect(t.execute("disconnect drive").first).to be_instance_of Response
    end
	end

	describe 'ff' do
    it 'respond to description_ff' do
      expect(t).to respond_to(:description_ff)
    end

    it 'respond to usage_ff' do
      expect(t).to respond_to(:usage_ff)
    end

    it 'respond with Response object' do
      expect(t.execute("ff").first).to be_instance_of Response
    end
	end

	describe 'fb' do
    it 'respond to description_fb' do
      expect(t).to respond_to(:description_fb)
    end

    it 'respond to usage_fb' do
      expect(t).to respond_to(:usage_fb)
    end

    it 'respond with Response object' do
      expect(t.execute("fb").first).to be_instance_of Response
    end
	end

	describe 'repeat' do
    it 'respond to description_repeat' do
      expect(t).to respond_to(:description_repeat)
    end

    it 'respond to usage_repeat' do
      expect(t).to respond_to(:usage_repeat)
    end

    it 'respond with Response object' do
      expect(t.execute("repeat").first).to be_instance_of Response
    end
	end
end
