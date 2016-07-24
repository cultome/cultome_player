module CultomePlayer
  module Objects
    class Response
      attr_reader :data

      def initialize(type, data)
        @success = type == :success
        @data = data

        @data.each do |k,v|
          self.singleton_class.send(:define_method, k) do
            v
          end
        end
      end

      # Check if the success data associated to the response is false.
      #
      # @return [Boolean] True if success data is false, False otherwise.
      def failure?
        !@success
      end

      # Check if the success data associated to the response is true.
      #
      # @return [Boolean] True if success data is true, False otherwise.
      def success?
        @success
      end

      # Join two response together. The response type makes an OR and parameter response's data is merged into.
      #
      # @param response [Response] The response to join.
      # @return [Response] The calculated new response.
      def +(response)
        type = success? && response.success? ? :success : :failure
        data = @data.merge response.data
        return Response.new(type, data)
      end

      def to_s
        "Response #{success? ? 'successful' : 'failed'} => #{@data}"
      end
    end
  end
end
