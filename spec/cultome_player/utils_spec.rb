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

  it 'display messages in color' do
    expect(t.c1("COLOR")).to eq "\e[0;34;49mCOLOR\e[0m"
    expect(t.c2("COLOR")).to eq "\e[0;30;49mCOLOR\e[0m"
    expect(t.c3("COLOR")).to eq "\e[0;31;49mCOLOR\e[0m"
    expect(t.c4("COLOR")).to eq "\e[0;32;49mCOLOR\e[0m"
    expect(t.c5("COLOR")).to eq "\e[0;33;49mCOLOR\e[0m"
    expect(t.c6("COLOR")).to eq "\e[0;34;49mCOLOR\e[0m"
    expect(t.c8("COLOR")).to eq "\e[0;36;49mCOLOR\e[0m"
    expect(t.c9("COLOR")).to eq "\e[0;37;49mCOLOR\e[0m"
    expect(t.c10("COLOR")).to eq "\e[0;39;49mCOLOR\e[0m"
    expect(t.c11("COLOR")).to eq "\e[0;90;49mCOLOR\e[0m"
    expect(t.c12("COLOR")).to eq "\e[0;91;49mCOLOR\e[0m"
    expect(t.c13("COLOR")).to eq "\e[0;92;49mCOLOR\e[0m"
    expect(t.c14("COLOR")).to eq "\e[0;93;49mCOLOR\e[0m"
    expect(t.c15("COLOR")).to eq "\e[0;94;49mCOLOR\e[0m"
    expect(t.c16("COLOR")).to eq "\e[0;95;49mCOLOR\e[0m"
    expect(t.c17("COLOR")).to eq "\e[0;96;49mCOLOR\e[0m"
    expect(t.c18("COLOR")).to eq "\e[0;97;49mCOLOR\e[0m"
  end

  it '#ensure_db_schema' do
    expect{ t.ensure_db_schema }.not_to raise_error
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
