
module CultomePlayer::Core::Importer
  def import_folder(path)
    files = find_files_in_folder path
    files.each.with_object([]) do |filepath,acc|
      acc << read_id3_tag(filepath)
    end
  end

  private

  def read_id3_tag(filepath)
    {
      path: filepath,
    }
  end

  def find_files_in_folder(path)
    abs_folder_path = File.absolute_path path

    Dir.children(abs_folder_path).flat_map do |file|
      abs_file_path = File.join(abs_folder_path, file)

      if File.directory?(abs_file_path)
        find_files_in_folder(abs_file_path)
      else
        abs_file_path
      end
    end
  end
end
