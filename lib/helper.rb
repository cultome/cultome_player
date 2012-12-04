require 'active_support/inflector'
require 'mp3info'

module Helper

  def extract_mp3_information(file_path)
    info = nil
    Mp3Info.open(file_path) do |mp3|
      info = {
        name: mp3.tag.title,
        artist: mp3.tag.artist,
        album: mp3.tag.album,
        track: mp3.tag.tracknum,
        duration: mp3.length,
        year: mp3.tag1["year"]
      }
    end

    if info[:name].nil?
      info[:name] = file_path.split('/').last
    end

    return polish(info)
  end

  def polish(info)
    [:name, :artist, :album].each{|k| info[k] = info[k].strip.titleize unless info[k].nil? }
    [:track, :year].each{|k| info[k] = info[k].to_i if info[k] =~ /\A[\d]+\Z/ }
    info[:duration] = info[:duration].to_i

    info
  end

  def to_time(seconds)
    "#{(seconds/60).to_s.rjust(2, '0')}:#{(seconds%60).to_s.rjust(2, '0')}"
  end
end