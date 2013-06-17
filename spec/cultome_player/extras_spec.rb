require 'spec_helper'

describe CultomePlayer::Extras do

    let(:t) do
        class1 = Class.new do
            include CultomePlayer
        end

        class1.new
    end

    let(:t2) do
        class2 = Class.new do
            include CultomePlayer
        end

        class2.new
    end

    before :each do
        @test_config_file = "#{ t.project_path }/spec/config.tmp"

        t.set_environment({
            config_file: @test_config_file
        })

        t2.set_environment({
            config_file: @test_config_file
        })
    end

    after :each do
        File.delete(@test_config_file) if File.exist?(@test_config_file)
    end

    it 'create an empty configuration for every extra' do
        t.extras_config.should eq({})
        t2.extras_config.should eq({})
    end

    it 'create a separate configuration space for every extra' do
        ns1 = t.extras_config
        ns1[:uno] = "Uno"

        ns2 = t2.extras_config
        ns2[:uno].should be_nil

        ns2[:dos] = "Dos"
        ns1[:dos].should be_nil
    end

    context 'with temporal config file' do
        before :each do
            File.delete(@test_config_file) if File.exist?(@test_config_file)
        end

        it 'save configurations in file' do
            File.exist?(@test_config_file).should be_false
            t.extras_config
            t.save_extras_config_file
            File.exist?(@test_config_file).should be_true
        end
    end
end
