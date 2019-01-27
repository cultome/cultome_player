
RSpec.describe CultomePlayer::Core::Search do
  it "finds a song by value" do
    expect(search_by_value("Fire").size).to be > 0
  end
end
