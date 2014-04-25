module CultomePlayer
  module Objects
    class Parameter
      include CultomePlayer::Utils

      # Initialize a parameter with the data provided.
      #
      # @param data [Hash] Contains the keys :criteria, :value, :type
      def initialize(data)
        @data = data
      end

      # Get the criteria asocciated with the parameter, if any.
      def criteria
        return nil if @data[:criteria].nil?
        @data[:criteria].to_sym
      end

      # Returns the value associated with the parameter in its appropiated type.
      #
      # @return [Object] The value of the parameter.
      def value
        return is_true_value?(@data[:value]) if @data[:type] == :boolean
        return @data[:value].to_i if @data[:type] == :number
        return @data[:value].to_sym if @data[:type] == :object
        return raw_value
      end

      # Return the value as the user input typed (no conversions).
      #
      # @return [String] The values of the parameter as the user typed.
      def raw_value
        @data[:value]
      end

      # Returns the type associated with the parameter.
      #
      # @return [Symbol] The type of the parameter.
      def type
        @data[:type]
      end
    end
  end
end