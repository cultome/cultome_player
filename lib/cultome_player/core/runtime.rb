require "json"

module CultomePlayer::Core::Runtime
  def library(force_reload=false)
    @library = load_library if force_reload

    get_library
  end

  private

  def get_library
    @library ||= load_library
  end

  def load_library
    JSON.load(File.read(db_file))
  rescue
    raise "Database is corrupted! Delete the file ~/.cultome_player/db.json and restart the player"
  end
end
