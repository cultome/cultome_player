require 'spec_helper'

describe CultomePlayer::Player::Interface::Extended do
  let(:t){ TestClass.new }

  it 'repeats a song from the beginning' do
  	t.should_receive(:send_to_player).with(/^jump 0$/)
  	t.repeat(nil)
  end

	describe 'search' do
    it 'respond to description_search' do
      t.should respond_to(:description_search)
    end

    it 'respond to usage_search' do
      t.should respond_to(:usage_search)
    end

    it 'respond with Response object' do
      t.execute("search on").first.should be_instance_of Response
    end
	end

	describe 'show' do
    it 'respond to description_show' do
      t.should respond_to(:description_show)
    end

    it 'respond to usage_show' do
      t.should respond_to(:usage_show)
    end

    it 'respond with Response object' do
      t.execute("show").first.should be_instance_of Response
    end
	end

	describe 'enqueue' do
    it 'respond to description_enqueue' do
      t.should respond_to(:description_enqueue)
    end

    it 'respond to usage_enqueue' do
      t.should respond_to(:usage_enqueue)
    end

    it 'respond with Response object' do
      t.execute("enqueue on").first.should be_instance_of Response
    end
	end

	describe 'shuffle' do
    it 'respond to description_shuffle' do
      t.should respond_to(:description_shuffle)
    end

    it 'respond to usage_shuffle' do
      t.should respond_to(:usage_shuffle)
    end

    it 'respond with Response object' do
      t.execute("shuffle on").first.should be_instance_of Response
    end
	end

	describe 'connect' do
    it 'respond to description_connect' do
      t.should respond_to(:description_connect)
    end

    it 'respond to usage_connect' do
      t.should respond_to(:usage_connect)
    end

    it 'respond with Response object' do
      t.execute("connect drive").first.should be_instance_of Response
    end
	end

	describe 'disconnect' do
    it 'respond to description_disconnect' do
      t.should respond_to(:description_disconnect)
    end

    it 'respond to usage_disconnect' do
      t.should respond_to(:usage_disconnect)
    end

    it 'respond with Response object' do
      t.execute("disconnect drive").first.should be_instance_of Response
    end
	end

	describe 'ff' do
    it 'respond to description_ff' do
      t.should respond_to(:description_ff)
    end

    it 'respond to usage_ff' do
      t.should respond_to(:usage_ff)
    end

    it 'respond with Response object' do
      t.execute("ff").first.should be_instance_of Response
    end
	end

	describe 'fb' do
    it 'respond to description_fb' do
      t.should respond_to(:description_fb)
    end

    it 'respond to usage_fb' do
      t.should respond_to(:usage_fb)
    end

    it 'respond with Response object' do
      t.execute("fb").first.should be_instance_of Response
    end
	end

	describe 'repeat' do
    it 'respond to description_repeat' do
      t.should respond_to(:description_repeat)
    end

    it 'respond to usage_repeat' do
      t.should respond_to(:usage_repeat)
    end

    it 'respond with Response object' do
      t.execute("repeat").first.should be_instance_of Response
    end
	end
end