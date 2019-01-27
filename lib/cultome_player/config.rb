
module CultomePlayer::Config
  def db_file
    File.join(base_dir, "db.json")
  end

  def base_dir
    File.expand_path "~/.cultome_player"
  end
end
