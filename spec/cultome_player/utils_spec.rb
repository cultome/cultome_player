require 'spec_helper'

describe CultomePlayer::Utils do
	let(:t){ TestClass.new(:rspec) }

	describe 'arrange information in columns' do
		it 'everything fits in a row' do
			t.arrange_in_columns(["12345", "1234567890"], [5, 10], 2).should eq "12345  1234567890"
		end

		it 'data bigger than column span into another row' do
			t.arrange_in_columns(["12345", "123456789012345"], [5, 10], 2).should eq "12345  1234567890\n       12345"
		end
	end
end