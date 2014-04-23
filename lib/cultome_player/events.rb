module CultomePlayer
  module Events

    # Lazy getter of registered event listeners.
    #
    # @return [Hash] With event names as the keys and values are the listeners registered to that event.
    def listeners
      @listeners ||= Hash.new{|h,k| h[k] = [] }
    end

    # Register a listener to an event.
    #
    # @param event [Symbol] The event name.
    # @param listener [Object] Implements a callback with the name on_<event name>.
    # @return [Object] The registered listener.
    def register_listener(event, listener)
      listeners[event] << listener
      return listener
    end

    # Broadcast an event to all the registered listeners.
    #
    # @param event [Symbol] The event name.
    # @param data [Array] The information sended to the listeners.
    def emit_event(event, *data)
      listeners[event].collect{|l| l.send("on_#{event}".to_sym, *data) }
    end
  end
end
