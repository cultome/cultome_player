module CultomePlayer
  module Objects
    class Command
      attr_reader :action
      attr_reader :parameters

      def initialize(action, parameters)
        @action = action[:value]
        @parameters = parameters.collect{|p| Parameter.new(p) }
      end

      def params(type=nil)
        return @parameters if type.nil?
        @parameters.select{|p| p.type == type}
      end

      def params_groups
        @parameters.collect{|p| p.type }.each_with_object({}){|type,acc| acc[type] = params(type) }
      end

      def params_values(type)
        params(type).map{|p| p.value }
      end
    end

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