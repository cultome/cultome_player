module CultomePlayer
  module Objects
    class Parameter
      include CultomePlayer::Utils

      def initialize(data)
        @data = data
      end

      def criteria
        @data[:criteria].to_sym
      end

      def value
        return is_true_value?(@data[:value]) if @data[:type] == :boolean
        return @data[:value].to_i if @data[:type] == :number
        return @data[:value].to_sym if @data[:type] == :object
        @data[:value]
      end

      def type
        @data[:type]
      end
    end
  end
end