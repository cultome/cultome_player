require 'spec_helper'

describe CultomePlayer do
	let(:t){ TestClass.new(:rspec) }

	it 'executes built int commands' do
		expect(t.execute('search way')).not_to be_nil
	end

	it 'executes plugins' do
		expect(t.execute('help')).not_to be_nil
	end

	it 'contains usage instrucctions' do
		expect(t).to respond_to(:usage_cultome_player)
	end

  it 'creates a default player' do
    player = CultomePlayer.get_player(:rspec)
    expect(player).not_to be_nil
  end

	describe 'multiple commands' do
		it 'executes all commands' do
			expect(t).to receive(:command_help).twice.and_call_original
			expect(t).to receive(:command_alias).and_call_original
			r = t.execute("help && help play && alias play => al")
			expect(r.size).to eq 3
		end

		it 'executes until something fail' do
			expect(t).to receive(:command_help).and_call_original
			expect(t).to receive(:search).and_call_original
			expect(t).not_to receive(:fb)
			r = t.execute("help && search ksahdiasdyasdsa && fb 10")
		end

		it 'return the last element failing' do			
			r = t.execute("help && play && fb 10")
			expect(r.size).to eq 2
			expect(r.first).to be_success
			expect(r.last).not_to be_success
		end
	end
end
