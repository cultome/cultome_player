
module CultomePlayer::Core::Search
  def search_by_value(value)
    regex = /#{value}/i

    library.values.select do |record|
      record.album =~ regex || record.artist =~ regex || record.name =~ regex
    end
  end
end
