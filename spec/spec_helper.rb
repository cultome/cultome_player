require 'coveralls'
require 'database_cleaner'
require 'cultome_player'

Coveralls.wear!

include CultomePlayer::Environment
include CultomePlayer::Utils
include CultomePlayer::Objects

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.filter_run_excluding :mplayer
  config.order = 'random'

  config.before(:suite) do
    prepare_environment(:rspec)
    with_connection do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with(:truncation)
    end
  end

  config.before(:each) do
    with_connection { DatabaseCleaner.start }
  end

  config.after(:each) do
    with_connection { DatabaseCleaner.clean }
  end
end

module FakeStatus
  def current_artist
    Artist.new(name: 'artist_uno')
  end

  def current_album
    Album.new(name: 'album_tres')
  end
end

module FakeExtractor
  def extract_from_txt(filepath, opc)
    filename = filepath[filepath.rindex("/")+1, filepath.length]
    extension = filename[filename.rindex(".")+1, filename.length]

    file_info = { filename: filename, path: filepath, extension: extension }

    file_info[:relative_path] = filepath.gsub(/#{opc[:root_path]}\//, '') if opc.has_key?(:root_path)

      return file_info
  end
end

module MockPlayer
  def send_to_player(cmd)
    if cmd == 'pause'
      @paused = true
      @stopped = @playing = false
    elsif cmd.start_with?('osd_show_text')
      @paused = @stopped = false
      @playing = true
    elsif cmd.start_with?('loadfile')
      @playing = true
    elsif cmd.start_with?('stop')
      @is_player_running = @paused = @playing = false
      @stopped = true
    elsif cmd.start_with?('get_time_length')
      @playback_time_length = 120
    elsif cmd.start_with?('get_time_pos')
      @playback_time_position = 1
    else
      puts "ERROR: #{cmd} !!!!!!!"
    end
  end

  def control_pipe
    STDOUT
  end

  def start_player_with(song)
    @is_player_running = @playing = true
    @paused = @stopped = false
  end
end

class TestClass
  include CultomePlayer
  include FakeStatus
  include FakeExtractor
  include MockPlayer

  def initialize(env=:rspec)
    prepare_environment(env) unless env.nil?
    playlists.register(:current)
    playlists.register(:history)
    playlists.register(:queue)
    playlists.register(:focus)
  end
end

def test_folder
  File.join(File.dirname(File.expand_path(__FILE__)), 'test')
end
