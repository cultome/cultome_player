require 'cultome_player/extras'

module Kernel
    def blank?
        respond_to?(:empty?) ? empty? : !self
    end
end

class Fixnum
    # Convert an amount of seconds to its representation mm:ss
    #
    # @param seconds [Integer] The number of seconds to convert.
    # @return [String] A time representation of mm:ss
    def to_time
        "#{(self/60).to_s.rjust(2, '0')}:#{(self%60).to_s.rjust(2, '0')}"
    end
end

class ActiveRecord::Base
    include CultomePlayer::Extras::Colors
end

# abrimos algunas clases con propositos utilitarios
class Array
    def to_s
        idx = 0
        self.collect{|e| "#{( idx += 1 ).to_s.rjust(4)} #{e}" }.join("\n")
    end
end

