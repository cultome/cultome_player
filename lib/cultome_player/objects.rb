require 'active_record'
require 'cultome_player/utils'

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
    end

    class Parameter
      include CultomePlayer::Utils

      def initialize(data)
        @data = data
      end

      def criteria
        @data[:criteria]
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

    end # Response

    # The ActiveRecord model for Song objects.
    class Song < ActiveRecord::Base
      belongs_to :artist
      belongs_to :album
      has_and_belongs_to_many :genres
      belongs_to :drive
      has_many :similars, as: :similar

      scope :connected, -> {joins(:drive).where('drives.connected' => true)}
      # Get the full path to the song file.
      #
      # @return [String] The full path to the song file.
      def path
        File.join(self.drive.path, self.relative_path)
      end

      def to_s
        str = c4(":::: Song: ")
        str += c10(self.name)

        unless self.artist.nil?
          str += c4(" \\ Artist: ")
          str += c11(self.artist.name)
        end

        unless self.album.nil?
          str += c4(" \\ Album: ")
          str += c13(self.album.name)
        end
        str += c4(" ::::")
      end
    end

    # The ActiveRecord model for Artist objects.
    class Artist < ActiveRecord::Base
      has_many :songs
      has_many :albums, through: :songs
      has_many :similars, as: :similar

      def to_s
        str = c4(":::: Artist: ")
        str += c11(self.name)
        str += c4(" ::::")
      end
    end

    # The ActiveRecord model for Album objects.
    class Album < ActiveRecord::Base
      has_many :songs
      has_many :artists, through: :songs

      def to_s
        str = c4(":::: Album: ")
        str += c13(self.name)
        str += c4(" \\ Artist: ")
        unless self.artists.nil? || self.artists.empty?
          str += c11(self.artists.uniq.collect{|a| a.name}.join(', '))
        end
        str += c4(" ::::")
      end
    end

    # The ActiveRecord model for Genre objects.
    class Genre < ActiveRecord::Base
      has_and_belongs_to_many :songs

      def to_s
        str = c4(":::: Genre: ")
        str += c15(self.name)
        str += c4(" ::::")
      end
    end

    # The ActiveRecord model for Drive objects.
    class Drive < ActiveRecord::Base
      has_many :songs

      def connected?
        connected
      end

      def to_s
        str = c4(":::: Drive: ")
        str += c14(self.name)
        str += c4(" => ")
        str += c14(self.songs.size.to_s)
        str += c4(" songs => ")
        str += c14(self.path)
        str += c4(" => ")
        str += connected ? c3("Online") : c2("Offline")
        str += c4(" ::::")
      end
    end
  end
end
