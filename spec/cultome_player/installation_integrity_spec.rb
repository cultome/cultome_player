require 'spec_helper'

describe CultomePlayer::InstallationIntegrity do
    let(:t){ Test.new }

    it 'Should check directories integrity' do
        t.check_directories_integrity.should be_nil
    end

    it 'Should check config files integrity' do
        t.check_config_files_integrity.should be_nil
    end

    it 'Should check database integrity' do
        t.check_database_integrity.should_not be_nil
    end

    it 'Should check full integrity' do
        t.check_integrity.should_not be_nil
    end
end
