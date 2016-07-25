require 'spec_helper'

describe CultomePlayer::Utils do
	let(:t){ TestClass.new(:rspec) }

  it 'displays a message' do
    msg = t.display("My message")
    expect(msg).to eq t._output.string
  end

  it 'displays a message over the previous one' do
    msg = t.display_over("My message overwrited")
    expect(msg).to eq t._output.string
  end

	describe 'arrange information in columns' do
		it 'everything fits in a row' do
			expect(t.arrange_in_columns(["12345", "1234567890"], [5, 10], 2)).to eq "12345  1234567890"
		end

		it 'data bigger than column span into another row' do
			expect(t.arrange_in_columns(["12345", "123456789012345"], [5, 10], 2)).to eq "12345  1234567890\n       12345"
		end
	end
end
