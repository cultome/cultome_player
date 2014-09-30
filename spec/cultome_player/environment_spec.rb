require 'spec_helper'

describe CultomePlayer::Environment do
  let(:t){ TestClass.new(nil) }

  it 'prepare environment' do
    t.prepare_environment(:rspec)
    t.recreate_db_schema
    t.env_config.should_not be_empty
  end

  context 'with no environment loaded' do
    it 'raise exception when using mplayer_pipe' do
      expect{ t.mplayer_pipe }.to raise_error('environment problem:environment information not loaded')
    end

    it 'raise exception when using db_adapter' do
      expect{ t.db_adapter }.to raise_error('environment problem:environment information not loaded')
    end

    it 'raise exception when using db_file' do
      expect{ t.db_file }.to raise_error('environment problem:environment information not loaded')
    end
    it 'raise exception when using db_log_file' do
      expect{ t.db_log_file }.to raise_error('environment problem:environment information not loaded')
    end

    it 'raise exception when using file_types' do
      expect{ t.file_types }.to raise_error('environment problem:environment information not loaded')
    end

    it 'raise exception when using config_file' do
      expect{ t.config_file }.to raise_error('environment problem:environment information not loaded')
    end
  end

  context 'with environment loaded' do
    before :each do
      t.prepare_environment(:rspec)
      t.recreate_db_schema
    end

    it 'load the db_adapter' do
      t.db_adapter.should eq 'sqlite3'
    end

    it 'load the mplayer_pipe' do
      t.mplayer_pipe.should end_with 'spec/mpctr'
    end

    it 'load the db_file' do
      t.db_file.should end_with 'spec/db.dat'
    end

    it 'load the db_log_file' do
      t.db_log_file.should end_with 'spec/db.log'
    end

    it 'load the file_types' do
      t.file_types.should eq 'mp3'
    end

    it 'load the config_file' do
      t.config_file.should end_with 'spec/config.yml'
    end
  end
end
