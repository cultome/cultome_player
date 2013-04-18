require 'spec_helper'
require 'cultome/user_input'

class Test
	include UserInput

	def initialize
		@command_registry = {prev: nil, play: nil, pause: nil, search: nil}
	end

	def display(msg)
	end
end

describe UserInput do

	let(:u){ Test.new }

	it 'Should return a valid aliases regex' do
		u.valid_alias.should match(/([\w]+?\|?)+/)
	end

	it 'Should return a valid commands regex' do
		u.valid_command.should match(/([\w]+?\|?)+/)
	end

	it 'Should parse an user input into a command' do
		u.parse('play something').should eq([{
			command: :play,
			params: [{type: :literal, value: 'something'}]
		}])
	end

	it 'Should parse an user input into a commands list' do
		u.parse('play something | search a:else').should eq([{
			:command=>:search, 
			:params=>[
				{:criteria=>:a, :value=>"else", :type=>:criteria},
			   	{:type=>:command, 
				:value=>{
					:command=>:play, 
					:piped=>true,
					:params=>[{:value=>"something", :type=>:literal}]
				}}
			]
		}])
	end

	it 'Should ask and receive an afirmative confirmation from user' do
		u.should_receive(:display).once.with('message')
		u.stub(:get_command).and_return('y')
		u.get_confirmation('message').should be_true
	end

	it 'Should ask and receive a negative confirmation from user' do
		u.should_receive(:display).once.with('message')
		u.stub(:get_command).and_return('n')
		u.get_confirmation('message').should be_false
	end

	it 'Should recognize as afirmative expression /Y|y|yes|1|si|s|ok/' do
		%w{Y y yes 1 si s ok}.each{|y| u.is_true_value(y).should be_true }
	end

	it 'Should parse a user input into a single command' do
		u.send(:parse_command, 'play one').should eq({
			command: :play,
			params: [{type: :literal, value: 'one'}]
		})
	end

	it 'Should parse correctly all the parameter types' do
		# numerics
		u.send(:parse_params,%w{1 21 10000000000}).should eq([
		   {value: '1', type: :number},
		   {value: '21', type: :number},
		   {value: '10000000000', type: :number},
		])
		# path
		u.send(:parse_params,%w{/home/user /root/}).should eq([
			{value: '/home/user', type: :path},
			{value: '/root', type: :path},
		])
		# criteria
		u.send(:parse_params,%w{a:uno b:dos t:tres_cuatro}).should eq([
			{value: 'uno', criteria: :a, type: :criteria},
			{value: 'dos', criteria: :b, type: :criteria},
			{value: 'tres_cuatro', criteria: :t, type: :criteria},
		])
		# object
		u.send(:parse_params,%w{@one @two @three_four}).should eq([
			{value: :one, type: :object},
			{value: :two, type: :object},
			{value: :three_four, type: :object},
		])
		# literal
		u.send(:parse_params,%w{pedro pablo paco}).should eq([
			{value: 'pedro', type: :literal},
			{value: 'pablo', type: :literal},
			{value: 'paco', type: :literal},
		])
		# bubble word
		u.send(:parse_params,%w{=>}).should be_empty
		# unknown
		u.send(:parse_params,%w{0 8:qwerty}).should eq([
			{value: '0', type: :unknown},
			{value: '8:qwerty', type: :unknown},
		])
	end
end
