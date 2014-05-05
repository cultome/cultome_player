module CultomePlayer
  module Objects
    class Command
      attr_reader :action
      attr_reader :parameters

      def initialize(action, parameters)
        @action = action[:value]
        @parameters = parameters.collect{|p| Parameter.new(p) }
        @no_history = params(:literal).any?{|p| p.value == 'no_history'}
      end

      def history?
        !@no_history
      end

      # Returns the parameters, optionally filtered by type
      #
      # @param type [Symbol] Parameter type to filter the results
      # @return [List<Parameter>] The parameters associated with the command, optionally filtered.
      def params(type=nil)
        return @parameters if type.nil?
        @parameters.select{|p| p.type == type}
      end

      # Returns a map that contains parameter type as key and a list of the parameters of that type as value.
      #
      # @return [Hash<Symbol, List<Parameter>>] Parameters grouped by type.
      def params_groups
        @parameters.collect{|p| p.type }.each_with_object({}){|type,acc| acc[type] = params(type) }
      end

      # Returns a list with only the parameters values of certain type.
      #
      # @param type [Symbol] The type of parameters.
      # @return [List<Object>] The values of the parameters.
      def params_values(type)
        params(type).map{|p| p.value }
      end

      def to_s
        "#{action} #{@parameters}"
      end
    end
  end
end