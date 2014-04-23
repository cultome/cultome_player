require 'spec_helper'

describe CultomePlayer do
	let(:t){ TestClass.new(:rspec) }

	it 'executes built int commands' do
		t.execute('search way').should_not be_nil
	end

	it 'executes plugins' do
		t.execute('help').should_not be_nil
	end

	it 'contains usage instrucctions' do
		t.should respond_to(:help_cultome_player)
	end
end