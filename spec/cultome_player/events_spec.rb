require 'spec_helper'

describe CultomePlayer::Events do
  let(:t){ TestClass.new }

  it 'register event listeners' do
    t.listeners.should be_empty
    t.register_listener(:my_event){ "OK 1!" }
    t.listeners.should have(1).item
  end

  it 'callback listeners on event' do
    t.register_listener(:my_event){|data| "#{data} 1!" }
    t.register_listener(:my_event){|data| "#{data} 2!" }
    r = t.emit_event(:my_event, "DATA")
    r.should eq ["DATA 1!", "DATA 2!"]
  end
end
