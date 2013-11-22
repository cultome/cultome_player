require 'taglib'

module CultomePlayer
  module Media
    def extract_from_mp3(filepath, opc={})
      info = nil
      TagLib::FileRef.open(filepath) do |mp3|
        unless mp3.nil?
          info = {
            # file information
            file_path: filepath,
            library_path: opc[:library_path],
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
      end

      if info[:name].nil?
        info[:name] = filepath.split('/').last
      end

      return polish_mp3_info(info)
    end

    private 

    def polish_mp3_info(info)
      [:genre, :name, :artist, :album].each{|k| info[k] = info[k].downcase.strip.titleize unless info[k].nil? }
      [:track, :year].each{|k| info[k] = info[k].to_i if info[k] =~ /\A[\d]+\Z/ }
      info[:duration] = info[:duration].to_i

      return info
    end

  end
end
