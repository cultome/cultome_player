
module CultomePlayer::Utils
  def db_file_exists?
    File.exists?(db_file)
  end

  def create_db_file
    Dir.mkdir(base_dir) unless File.exists?(base_dir)
    File.write(db_file, "[]")
  end
end
