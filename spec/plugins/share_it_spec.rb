require 'spec_helper'
require 'cultome/persistence'
require 'plugins/share_it'

describe Plugin::ShareIt do

	let(:s){ Plugin::ShareIt.new(get_fake_player, {})}
	let(:c){ Plugin::ShareIt.new(get_fake_player, {})}

	context '#share' do
		before :each do
			@server_pid = fork do
				s.receive([
					{type: :path, value: 'spec/data/received'},
					{type: :literal, value: '12345'},
				])
			end
		end

		after do
			Process.waitpid(@server_pid)
			File.delete("spec/data/received/music.mp3")
		end

		def client_tester(params)
			client_pid = fork do
				exit 1 unless c.share(params)
			end
			Process.waitpid(client_pid)
			$?.exitstatus.should == 0
			File.exist?('spec/data/received/music.mp3').should be_true
		end

		it 'Should transfer a file with hostname and number' do
			client_tester([
				{type: :literal, value: 'localhost'},
				{type: :number, value: 12345}
			])
		end

		it 'Should transfer a file with hostname and number' do
			client_tester([
				{type: :literal, value: 'localhost'},
				{type: :number, value: 12345}
			])
		end

		it 'Should transfer a file with hostname and literal' do
			client_tester([
				{type: :literal, value: 'localhost'},
				{type: :literal, value: '12345'}
			])
		end

		it 'Should transfer a file with ip and number' do
			client_tester([
				{type: :ip, value: '127.0.0.1'},
				{type: :number, value: 12345}
			])
		end

		it 'Should transfer a file with ip and literal' do
			client_tester([
				{type: :ip, value: '0.0.0.0'},
				{type: :literal, value: '12345'}
			])
		end
	end

	context '#receive' do
		after do
			File.delete("spec/data/received/music.mp3")
		end

		it 'Should receive a file with path and number' do
			server_tester([
				{type: :path, value: 'spec/data/received'},
				{type: :number, value: 12345}
			])
		end

		it 'Should receive a file with path and literal' do
			server_tester([
				{type: :path, value: 'spec/data/received'},
				{type: :literal, value: '12345'}
			])
		end

		it 'Should receive a file with drive and number' do
			Drive.stub!(:find_by_name).with("drive").and_return(stub(path: "spec/data/received"))
			server_tester([
				{type: :object, value: 'drive'},
				{type: :number, value: 12345}
			])
		end

		it 'Should receive a file with drive and literal' do
			Drive.stub!(:find_by_name).with("drive").and_return(stub(path: "spec/data/received"))
			server_tester([
				{type: :object, value: 'drive'},
				{type: :literal, value: '12345'}
			])
		end

		def server_tester(params)
			server_pid = fork do
				exit 1 unless s.receive(params)
			end
			run_client
			Process.waitpid(server_pid)
			$?.exitstatus.should == 0
			File.exist?('spec/data/received/music.mp3').should be_true
		end

		def run_client
			client_pid = fork do
				exit 1 unless c.share([
					{type: :literal, value: 'localhost'},
					{type: :number, value: 12345},
				])
			end
			Process.waitpid(client_pid)
		end
	end
end
