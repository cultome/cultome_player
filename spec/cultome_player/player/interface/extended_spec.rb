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
      expect(t.description_search).not_to be_empty
    end

    it 'respond to usage_search' do
      expect(t).to respond_to(:usage_search)
      expect(t.usage_search).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("search on").first).to be_instance_of Response
    end
  end

  describe 'show' do
    it 'respond to description_show' do
      expect(t).to respond_to(:description_show)
      expect(t.description_show).not_to be_empty
    end

    it 'respond to usage_show' do
      expect(t).to respond_to(:usage_show)
      expect(t.usage_show).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("show").first).to be_instance_of Response
    end
  end

  describe 'enqueue' do
    it 'respond to description_enqueue' do
      expect(t).to respond_to(:description_enqueue)
      expect(t.description_enqueue).not_to be_empty
    end

    it 'respond to usage_enqueue' do
      expect(t).to respond_to(:usage_enqueue)
      expect(t.usage_enqueue).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("enqueue on").first).to be_instance_of Response
    end
  end

  describe 'shuffle' do
    it 'respond to description_shuffle' do
      expect(t).to respond_to(:description_shuffle)
      expect(t.description_shuffle).not_to be_empty
    end

    it 'respond to usage_shuffle' do
      expect(t).to respond_to(:usage_shuffle)
      expect(t.usage_shuffle).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("shuffle on").first).to be_instance_of Response
    end
  end

  describe 'connect' do
    it 'respond to description_connect' do
      expect(t).to respond_to(:description_connect)
      expect(t.description_connect).not_to be_empty
    end

    it 'respond to usage_connect' do
      expect(t).to respond_to(:usage_connect)
      expect(t.usage_connect).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("connect drive").first).to be_instance_of Response
    end
  end

  describe 'disconnect' do
    it 'respond to description_disconnect' do
      expect(t).to respond_to(:description_disconnect)
      expect(t.description_disconnect).not_to be_empty
    end

    it 'respond to usage_disconnect' do
      expect(t).to respond_to(:usage_disconnect)
      expect(t.usage_disconnect).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("disconnect drive").first).to be_instance_of Response
    end
  end

  describe 'ff' do
    it 'respond to description_ff' do
      expect(t).to respond_to(:description_ff)
      expect(t.description_ff).not_to be_empty
    end

    it 'respond to usage_ff' do
      expect(t).to respond_to(:usage_ff)
      expect(t.usage_ff).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("ff").first).to be_instance_of Response
    end
  end

  describe 'fb' do
    it 'respond to description_fb' do
      expect(t).to respond_to(:description_fb)
      expect(t.description_fb).not_to be_empty
    end

    it 'respond to usage_fb' do
      expect(t).to respond_to(:usage_fb)
      expect(t.usage_fb).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("fb").first).to be_instance_of Response
    end
  end

  describe 'repeat' do
    it 'respond to description_repeat' do
      expect(t).to respond_to(:description_repeat)
      expect(t.description_repeat).not_to be_empty
    end

    it 'respond to usage_repeat' do
      expect(t).to respond_to(:usage_repeat)
      expect(t.usage_repeat).not_to be_empty
    end

    it 'respond with Response object' do
      expect(t.execute("repeat").first).to be_instance_of Response
    end
  end
end
