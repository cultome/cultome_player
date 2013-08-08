# encoding: utf-8
require 'colorize'

module CultomePlayer::Extras
  module Colors

    # Look for color methods and define them if necessary.
    def method_missing(mtd, *args, &block)
      return super unless mtd =~ /\Ac([\d]+)\Z/
        return super unless (1..colors_defined.size).include?($1.to_i) 
      define_color_methods unless @color_defined

      send(mtd, *args)
    end

    # Look for color methods and define them if necessary.
    def respond_to?(mtd, view_privates=false)
      return super unless mtd =~ /\Ac([\d]+)\Z/
        is_valid_color = (1..colors_defined.size).include?($1.to_i)
      define_color_methods if is_valid_color && !@color_defined

      return is_valid_color
    end

    # Accesor and initializator for the color palette.
    #
    # @return [Array<Symbol>] The color palette.
    def colors_defined
      @colors_defined ||= [
        :black,			# c1
        :red,			# c2
        :green,			# c3
        :yellow,		# c4
        :blue,			# c5
        :magenta,		# c6
        :cyan,			# c7
        :white,			# c8
        :default,		# c9
        :light_red,		# c10
        :light_green,	# c11
        :light_yellow,	# c12
        :light_blue,	# c13
        :light_magenta,	# c14
        :light_cyan,	# c15
        :light_white,	# c16
      ]
    end

    # Helper method to define the color methods
    def define_color_methods
      colors_defined.each_with_index do |color, idx|
        self.class_eval do
          define_method "c#{idx+1}" do |str|
            return str.send(color)
          end
        end
      end

      @colors_defined = true
    end
  end
end
