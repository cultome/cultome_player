require 'spec_helper'

describe CultomePlayer::Player::Interactive do
  let(:t){ TestClass.new }

  before :each do
    t.instance_variable_set("@in_session", true)
    t.emit_event(:interactive_session_started)
    t.execute "connect '#{test_folder}' => test"
  end

  it 'executes one command' do
    r = t.execute_interactively("show @library")
    expect(r).to match /:::: Song: /
  end

  it 'execute the previous command' do
    r1 = t.execute_interactively("show @library")
    r2 = t.execute_interactively("")
    expect(r1).to eq r2
  end

  it 'executes multiple commands' do
    t.execute_interactively("show @library")
    r1 = t.execute_interactively("play 1")
    r2 = t.execute_interactively("show @library && play 1")
    expect(r2).to eq r1
  end

  it 'catches an error during interactive session' do
    expect{ t.execute_interactively("show @") }.to raise_error "invalid command:invalid command"
  end

  it 'terminates a session' do
    expect(t.instance_variable_get("@in_session")).to be true
    t.terminate_session
    expect(t.instance_variable_get("@in_session")).to be false
  end

  it 'stores and retrives the last command executed' do
    expect(t).to receive(:set_last_command).and_call_original
    t.execute_interactively("show @library")
    cmd = t.last_command
    expect(cmd.to_s).to eq "show @library"
  end

  it 'display a successful response' do
    r1 = t.execute("show @library").first
    r2 = t.send(:show_response, r1)
    expect(r2).to match(/1 /).and match(/2 /).and match(/3 /)
  end

  it 'display an undefined response' do
    class T
      def to_s
        "test class"
      end
    end

    msg = double("msg", message: "one message", success?: true)
    res = double("response", response_type: :hash, hash: T.new)

    r1 = t.send(:show_response, "unknown response")
    expect(r1).to match "unknown response" # 3

    r2 = t.send(:show_response, msg)
    expect(r2).to match "one message" # 2

    r3 = t.send(:show_response, res)
    expect(r3).to match "\e[0;31;49m(((test class)))\e[0m\n" # 1
  end

  it 'displays an error response' do
    r1 = t.execute("show @invalid").first
    r2 = t.send(:show_error, r1.message)
    expect(r2).to match "I checked and there is nothing there."
  end

end
