require 'taglib'

module CultomePlayer
  module Media

    # Get information from ID3 tags in a mp3.
    #
    # @param filepath [String] The absolute path to the mp3 file.
    # @param opc [Hash] Additional parameters. Actually only :library_path is supported.
    # @return [Hash] With information extracted from ID3 tags.
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
      # si no se encontro nombre de la cancion en las etiquestas, usamos el nombre del archivo
      info[:name] = filepath.split('/').last if info[:name].nil?
      # limpiamos la informacion un poco
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
