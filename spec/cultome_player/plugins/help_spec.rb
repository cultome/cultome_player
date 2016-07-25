require 'spec_helper'

describe CultomePlayer::Plugins::Help do
	let(:t){ TestClass.new }

	it 'respond to command_help' do
		expect(t).to respond_to(:command_help)
	end

	it 'respond to sintax_help' do
		expect(t).to respond_to(:sintax_help)
	end

	it 'respond to usage_help' do
		expect(t).to respond_to(:usage_help)
	end

	it 'respond to description_help' do
		expect(t).to respond_to(:description_help)
	end

  it 'returns fail when no help available' do
    r = t.execute("help invalid").first
    expect(r.success?).to be false
    expect(r.data[:response_type]).to eq :message
  end

  it 'returns a general help usage message' do
    r = t.execute("help").first
    expect(r.success?).to be true
    expect(r.data[:response_type]).to eq :message
    expect(r.data[:message]).to match /usage: <command>/
  end
end
