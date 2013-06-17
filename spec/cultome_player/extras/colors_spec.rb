require 'spec_helper'

class MyTest
    include CultomePlayer
end

describe CultomePlayer::Extras::Colors do
    let(:t){ MyTest.new }

    it 'define color methods' do
        t.should_receive(:define_color_methods).and_call_original
        t.c4("TEST")
    end

    it 'respond to color methods' do
        t.should respond_to(:c10)
    end

    it 'dont respond to undefined colors' do
        t.should_not respond_to(:c20)
    end

    it 'raise an error when using undefined colors' do
        expect{ t.c99("TEST") }.to raise_error(NoMethodError)
    end
end
