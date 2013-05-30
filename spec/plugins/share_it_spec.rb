require 'spec_helper'
require 'plugins/share_it'

describe Plugins::ShareIt do

	let(:s){ Cultome::CultomePlayer.new }
	let(:c){ Cultome::CultomePlayer.new }

	context '#share', resources: true do
		before :each do
            @song = nil
            with_connection do
                begin
                    c.execute('play')
                    @song = $1 if c.song.relative_path =~ /([^\/]+?)\Z/
                end while @song !~ /\A[\w\d\s.-]+\Z/
            end

			@server_pid = fork do
				s.receive([
					{type: :path, value: 'spec/data/received'},
					{type: :literal, value: '12345'},
				])
			end
		end

		after do
			Process.waitpid(@server_pid)
			File.delete("spec/data/received/#{@song}")
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

		def client_tester(params)
			client_pid = fork do
				exit 1 unless c.share(params)
			end
			Process.waitpid(client_pid)
			$?.exitstatus.should == 0
			File.exist?("spec/data/received/#{@song}").should be_true
		end
	end

	context '#receive', resources: true do
        before :each do
            with_connection do
                c.execute('play')
                @song = $1 if c.song.relative_path =~ /([^\/]+?)\Z/
            end
        end

		after do
			File.delete("spec/data/received/#{@song}")
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
			Cultome::Drive.stub!(:find_by_name).with("drive").and_return(stub(path: "spec/data/received"))
			server_tester([
				{type: :object, value: 'drive'},
				{type: :number, value: 12345}
			])
		end

		it 'Should receive a file with drive and literal' do
			Cultome::Drive.stub!(:find_by_name).with("drive").and_return(stub(path: "spec/data/received"))
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
			File.exist?("spec/data/received/#{@song}").should be_true
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
