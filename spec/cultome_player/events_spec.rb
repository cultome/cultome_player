
RSpec.describe CultomePlayer::Events do
  it "receives events" do
    callback = spy("callback")

    subscribe_to "testing" do
      callback.done
    end

    emit "testing"

    expect(callback).to have_received(:done)
  end
end
