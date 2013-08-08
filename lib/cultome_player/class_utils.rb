# encoding: utf-8
require 'cultome_player/extras'

module Kernel
  # Check if a object is nil or empty.
  #
  # @return [Boolean] true if self is nil or empty, false otherwise.
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end
end

class Fixnum
  # Convert an amount of seconds to its representation mm:ss
  #
  # @return [String] A time representation of mm:ss
  def to_time
    "#{(self/60).to_s.rjust(2, '0')}:#{(self%60).to_s.rjust(2, '0')}"
  end
end

class ActiveRecord::Base
  include CultomePlayer::Extras::Colors
end

class Array

  # Prepend a number to every element in the list.
  #
  # @return [String] A numbered list with object's to_s elements.
  def to_s
    idx = 0
    self.collect{|e| "#{( idx += 1 ).to_s.rjust(4)} #{e}" }.join("\n")
  end
end

