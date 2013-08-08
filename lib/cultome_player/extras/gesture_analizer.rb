# encoding: utf-8
module CultomePlayer::Extras
  module GestureAnalizer

    def self.included(base)
      CultomePlayer::Player.register_event_listener(:command_executed, :add_gesture)
    end

    # Add a command to the events' queue, then analize the queue looking for patterns.
    #
    # @param commands [Array<Hash>] List with the user commands executed.
    def add_gesture(commands)
      commands.each do |cmd|
        user_actions.add(cmd)
      end
      analize_user_actions
    end

    # Look for known patterns and interpret them.
    def analize_user_actions
      # checamos el patron y vemos si matchea
      if user_actions.has(5, :next, 20)
        display c2("#### Notifying: Looking for something")
      end

      user_actions
    end

    # Hold the history of user actions in this player session.
    #
    # @return [EventQueue] The object holding the history of user actions.
    def user_actions
      @queue ||= EventQueue.new
    end


    # Support class. Usefull to manage the events in the GestureAnalizer.
    class EventQueue < Array

      # Add an event to the queue.
      #
      # @param event [Hash] With the command information.
      def add(event)
        cmd = event.clone
        cmd[:time] = Time.new
        cmd[:used] = false

        self.push(cmd)
      end

      def actions_with(event)
        self.select{|a| a[:command] == event }
      end

      # Check if a number of given events has ocurr, optionally in a given period of time.
      #
      # @param event_count [Integer] The repetitions of the given command.
      # @param event [Symbol] the command name.
      # @param within_time [Integer] The number of seconds in the searched sequence. If zero, no time period limit.
      # @return [Boolean] true if the sequence of events was found, false otherwise.
      def has(event_count, event, within_time=0)
        evts = self.select{|e| e[:command] == event && !e[:used]}
        if evts.size >= event_count
          consume = true

          if within_time > 0
            latest = evts.max{|a,b| a[:time] <=> b[:time] }
            oldest = evts.min{|a,b| a[:time] <=> b[:time] }

            consume = latest[:time] - oldest[:time] <= within_time
          end

          self.each{|e| e[:used] = true if e[:command] == event } if consume

          return consume
        end

        return false
      end
    end
  end
end
