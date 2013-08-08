require 'spec_helper'

describe Kernel do
  it 'respond to blank?' do
    "something".respond_to?(:blank?)
  end

  it 'check for blank state' do
    "another".should_not be_blank
  end
end
