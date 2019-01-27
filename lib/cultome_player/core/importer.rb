require "json"
require "taglib"

module CultomePlayer::Core::Importer
  def import_folder(path)
    files = find_files_in_folder path
    data = files.each.with_object({}) do |filepath,acc|
      acc[filepath] = read_id3_tag(filepath)
    end

    update_db_file(data)

    data
  end

  private

  def update_db_file(records)
    create_db_file unless db_file_exists?

    db_content = JSON.load(File.read(db_file))
    db_content.merge(records)
    open(db_file, "w"){|f| JSON.dump(db_content, f) }
  end

  def read_id3_tag(filepath)
    mp3 = TagLib::FileRef.new(filepath)
    return {file_path: filepath} if mp3.nil?

    {
      # file information
      file_path: filepath,
      # song information
      album: mp3.tag.album,
      artist: mp3.tag.artist,
      genre: mp3.tag.genre,
      name: mp3.tag.title,
      track: mp3.tag.track,
      year: mp3.tag.year,
      duration: mp3.audio_properties.length,
    }
  end

  def find_files_in_folder(path)
    abs_folder_path = File.absolute_path path

    Dir.children(abs_folder_path).flat_map do |file|
      next unless file.end_with?(".mp3")

      abs_file_path = File.join(abs_folder_path, file)

      if File.directory?(abs_file_path)
        find_files_in_folder(abs_file_path)
      else
        abs_file_path
      end
    end.compact
  end
end
