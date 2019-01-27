
module CultomePlayer::Core::Search
  def search_by_value(value)
    library.values.select do |record|
      record.values.any?{|field_value| field_value.include? value}
    end
  end
end
