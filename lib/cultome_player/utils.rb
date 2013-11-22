module CultomePlayer
  module Utils
    def is_true_value?(value)
      /true|yes|on|y|n|s|si|cierto/ === value 
    end
  end
end
