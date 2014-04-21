module CultomePlayer
  module Objects
    class Response
      attr_reader :data

      def initialize(type, data)
        @success = type == :success
        @data = data

        @data.each do |k,v|
          self.class.send(:define_method, k) do
            v
          end
        end
      end

      def failure?
        !@success
      end

      def success?
        @success
      end

      def +(response)
        type = success? && response.success? ? :success : :failure
        data = @data.merge response.data
        return Response.new(type, data)
      end
    end
  end
end
