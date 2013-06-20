require 'spec_helper'

describe CultomePlayer::Extras::CopyTo do

    let(:t){ Test.new }

    it 'respond to copy command' do
        t.should respond_to(:copy)
    end

    context 'with active playback' do

        before :each do
            t.should_receive(:valid_file_path?).and_return(true)
            t.play([{type: :literal, value: 'judas'}])
        end

        it 'copy a song into a folder in local filesystem' do
            t.should_receive(:system).once

            t.copy([
                   {type: :object, value: :song},
                   {type: :path, value: '/home/user/mypod'},
            ])
        end

        it 'copy a song list into a folder in local filesystem' do
            t.should_receive(:system).exactly(134).times

            t.copy([
                   {type: :object, value: :playlist},
                   {type: :path, value: '/home/user/mypod'},
            ])
        end
    end

    describe 'raise an error' do
        it 'there is no active playback' do
            expect{ t.copy([
                {type: :object, value: :song},
                {type: :path, value: "#{t.project_path}"},
            ]) }.to raise_error('no active playback')
        end

        describe 'with active playback' do

            before :all do
                @t = Test.new
                @t.play([{type: :literal, value: 'oasis'}])
            end

        it 'not only two parameters' do
            expect{ @t.copy([
                {type: :path, value: '/home/user/mypod'},
            ]) }.to raise_error('two parameters are required')
        end

        it 'not one object parameter' do
            expect{ @t.copy([
                {type: :literal, value: :playlist},
                {type: :path, value: '/home/user/mypod'},
            ]) }.to raise_error('one object parameter are required')
        end

        it 'not one path parameter' do
            expect{ @t.copy([
                {type: :object, value: :playlist},
                {type: :literal, value: '/home/user/mypod'},
            ]) }.to raise_error('one path parameter are required')
        end

        it 'invalid path parameter' do
            expect{ @t.copy([
                {type: :object, value: :playlist},
                {type: :path, value: '/home/user/mypod'},
            ]) }.to raise_error('the path parameter is not a valid directory')
        end

        it 'object parameter reference an empty list' do
            @t.should_receive(:valid_file_path?).and_return(true)
            expect{ @t.copy([
                {type: :object, value: :history},
                {type: :path, value: '/home/user/mypod'},
            ]) }.to raise_error("The object 'history' is empty!")
        end
    end
end
        end
