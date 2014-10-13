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
		t.should respond_to(:usage_cultome_player)
	end

	describe 'multiple commands' do
		it 'executes all commands' do
			expect(t).to receive(:command_help).twice.and_call_original
			expect(t).to receive(:command_alias).and_call_original
			r = t.execute("help && help play && alias play => al")
			r.should have(3).items
		end

		it 'executes until something fail' do
			expect(t).to receive(:command_help).and_call_original
			expect(t).to receive(:search).and_call_original
			expect(t).not_to receive(:fb)
			r = t.execute("help && search ksahdiasdyasdsa && fb 10")
		end

		it 'return the last element failing' do			
			r = t.execute("help && play && fb 10")
			r.should have(2).items
			r.first.should be_success
			r.last.should_not be_success
		end
	end
end
