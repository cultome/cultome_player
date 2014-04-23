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
  end
end