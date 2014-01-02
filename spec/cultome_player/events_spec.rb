require 'spec_helper'

describe CultomePlayer::Events do
  let(:t){ TestClass.new }
  let(:l1){ double(:listener1, :my_event => "OK 1!" ) }
  let(:l2){ double(:listener2, :my_event => "OK 2!" ) }

  it 'register event listeners' do
    t.listeners.should be_empty
    t.register_listener(:my_event, l1)
    t.listeners.should have(1).item
  end

  it 'callback listeners on event' do
    l1.should_receive(:my_event).with("DATA")
    l2.should_receive(:my_event).with("DATA")
    t.register_listener(:my_event, l1)
    t.register_listener(:my_event, l2)
    r = t.emit_event(:my_event, "DATA")
    r.should eq ["OK 1!", "OK 2!"]
  end
end
