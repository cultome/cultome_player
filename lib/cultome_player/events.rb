
module CultomePlayer::Events
  def subscribers
    @subscribers ||= Hash.new{|h,k| h[k] = []}
  end

  def emit(event, params={})
    subscribers[event].each do |subscriber|
      subscriber.call(params)
    end
  end

  def subscribe_to(event, &callback)
    subscribers[event].push(callback)
  end
end
