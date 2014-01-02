module CultomePlayer
  module Events
    def listeners
      @listeners ||= Hash.new{|h,k| h[k] = [] }
    end

    def register_listener(event, listener)
      listeners[event] << listener
    end

    def emit_event(event, *data)
      listeners[event].collect{|l| l.send(event, *data) }
    end
  end
end
