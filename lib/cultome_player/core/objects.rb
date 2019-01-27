require "forwardable"

module CultomePlayer::Core::Objects
  class Song
  end

  class Command
    attr_reader :action
    attr_reader :parameters

    def initialize(action, parameters)
      @action = action[:value]
      @parameters = parameters.collect{|p| Parameter.new(p) }
      @no_history = params(:literal).any?{|p| p.value == 'no_history'}
    end

    def history?
      !@no_history
    end

    # Returns the parameters, optionally filtered by type
    #
    # @param type [Symbol] Parameter type to filter the results
    # @return [List<Parameter>] The parameters associated with the command, optionally filtered.
    def params(type=nil)
      return @parameters if type.nil?
      @parameters.select{|p| p.type == type}
    end

    # Returns a map that contains parameter type as key and a list of the parameters of that type as value.
    #
    # @return [Hash<Symbol, List<Parameter>>] Parameters grouped by type.
    def params_groups
      @parameters.collect{|p| p.type }.each_with_object({}){|type,acc| acc[type] = params(type) }
    end

    # Returns a list with only the parameters values of certain type.
    #
    # @param type [Symbol] The type of parameters.
    # @return [List<Object>] The values of the parameters.
    def params_values(type)
      params(type).map{|p| p.value }
    end

    def to_s
      "#{action} #{@parameters.join(" ")}"
    end
  end

  class Parameter
    # Initialize a parameter with the data provided.
    #
    # @param data [Hash] Contains the keys :criteria, :value, :type
    def initialize(data)
      @data = data
    end

    # Get the criteria asocciated with the parameter, if any.
    def criteria
      return nil if @data[:criteria].nil?
      @data[:criteria].to_sym
    end

    # Returns the value associated with the parameter in its appropiated type.
    #
    # @return [Object] The value of the parameter.
    def value
      return is_true_value?(@data[:value]) if @data[:type] == :boolean
      return @data[:value].to_i if @data[:type] == :number
      return @data[:value].to_sym if @data[:type] == :object
      return raw_value
    end

    # Return the value as the user input typed (no conversions).
    #
    # @return [String] The values of the parameter as the user typed.
    def raw_value
      @data[:value]
    end

    # Returns the type associated with the parameter.
    #
    # @return [Symbol] The type of the parameter.
    def type
      @data[:type]
    end

    def to_s
      return case @data[:type]
        when :literal then @data[:value]
        when :criteria then "#{@data[:criteria]}:#{@data[:value]}"
        when :number then @data[:value]
        when :object then "@#{@data[:value]}"
        when :boolean then @data[:value]
        when :path then @data[:value]
        when :bubble then @data[:value]
        else value
      end
    end
  end

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

  class Playlist
    extend Forwardable

    attr_reader :songs

    def_delegator :@songs, :pop

    def initialize(songs=[])
      @songs = songs
      @repeat = false
      @current_song_index = 0
    end

    def add(*songs)
      @songs.concat(songs)
    end

    def shuffle
    end

    def current_song
      @songs[@current_song_index]
    end

    def prev_song
      @current_song_index -= 1
      current_song
    end

    def next_song
      @current_song_index = @repeat ? (@current_song_index + 1) % @songs.size : @current_song_index + 1
      current_song
    end

    def repeat=(enabled)
      @repeat = enabled
    end
  end

  class Playlists
    extend Forwardable

    def_delegator :@playlists, :size

    def initialize(playlists={})
      @playlists = playlists
    end

    def register(*names)
      names.each do |name|
        @playlists[name] ||= Playlist.new
      end
    end

    def get(*names)
      playlists = @playlists.select{|name,_| names.include? name }
      Playlists.new(playlists)
    end

    def pop
      songs = @playlists.map{|name,list| list.pop}
      songs.size == 1 ? songs.first : songs
    end

    def current_song
      songs = @playlists.map{|name,list| list.current_song }
      songs.size == 1 ? songs.first : songs
    end

    def next_song
      songs = @playlists.map{|name,list| list.next_song }
      songs.size == 1 ? songs.first : songs
    end

    def prev_song
      songs = @playlists.map{|name,list| list.prev_song }
      songs.size == 1 ? songs.first : songs
    end

    def repeat=(enabled)
      @playlists.each{|(name,list)| list.repeat = enabled }
    end

    def add(*songs)
      @playlists.each{|(name,list)| list.add(*songs) }
    end

    def songs
      @playlists.each.with_object([]){|(name,list),acc| acc.concat list.songs }
    end

    def shuffle
    end
  end
end
