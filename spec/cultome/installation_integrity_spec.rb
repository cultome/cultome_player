require 'spec_helper'
require 'cultome/installation_integrity'
require 'cultome_player'

describe Cultome::InstallationIntegrity do
    let(:p){ Cultome::CultomePlayer.new }

    it 'Should check directories integrity' do
        p.check_directories_integrity.should be_nil
    end

    it 'Should check config files integrity' do
        p.check_config_files_integrity.should be_nil
    end

    it 'Should check database integrity' do
        p.check_database_integrity.should_not be_nil
    end

    it 'Should check full integrity' do
        p.check_full_integrity.should_not be_nil
    end
end
