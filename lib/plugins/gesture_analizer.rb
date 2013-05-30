require 'cultome/helper'

module Plugins
    module GestureAnalizer
        extend Cultome::Helper

        # Register this listener for the events: All the events.
        # @note Required method for register listeners
        #
        # @return [List<Symbol>] The name of the events to listen.
        def self.get_listener_registry
            { __ALL_VALIDS__: :gesture}
        end

        # Add a command to the events' queue, then analize the queue looking for patterns.
        #
        # @param cmd [Hash] With the command information
        def self.gesture(cultome, params=[])
            cultome.last_cmds.each do |cmd|
                queue.add_event(cmd)
            end
            analize_queue(cultome)
        end

        # Look for known patterns and interpret them.
        def self.analize_queue(cultome)
            # checamos el patron y vemos si matchea
            if queue.has(5, :next, 20)
                display c2("#### Notifying: Looking for something")
            end

            queue
        end

        def self.queue
            @queue ||= GestureAnalizer::EventQueue.new
        end


        # Support class. Usefull to manage the events in the GestureAnalizer.
        class EventQueue
            def initialize
                @events = []
            end

            # Add an event to the queue.
            #
            # @param cmd [Hash] With the command information.
            def add_event(cmd)
                cmd[:time] = Time.new
                cmd[:used] = false

                @events.push(cmd)
            end

            # Check if a number of given events has ocurr, optionally in a given period of time.
            #
            # @param event_count [Integer] The repetitions of the given command.
            # @param event [Symbol] the command name.
            # @param within_time [Integer] The number of seconds in the searched sequence. If zero, no time period limit.
            # @return [Boolean] true if the sequence of events was found, false otherwise.
            def has(event_count, event, within_time=0)
                evts = @events.select{|e| e[:command] == event && !e[:used]}
                if evts.size >= event_count
                    consume = true

                    if within_time > 0
                        latest = evts.max{|a,b| a[:time] <=> b[:time] }
                        oldest = evts.min{|a,b| a[:time] <=> b[:time] }

                        consume = latest[:time] - oldest[:time] <= within_time
                    end

                    @events.each{|e| e[:used] = true if e[:command] == event } if consume

                    return consume
                end

                return false
            end
        end
    end
end
