require 'cultome_player/utils'

module CultomePlayer::Player::Playlist

  # Lazy getter for playlists.
  #
  # @return [Playlists] The playlists handled by the system.
  def playlists
    @playlists ||= Playlists.new
  end

  # (see Playlists#registered?)
  def playlist?(name)
    playlists.registered?(name)
  end

  class Playlists
    include Enumerable
    include CultomePlayer::Utils

    # Initialize a playlist with optional information to fill.
    #
    # @param data [#each] A collection of items to add to playlist
    def initialize(data=nil)
      @data = {}
      data.each{|arr| register(*arr) } unless data.nil?
    end

    # Register a playlist.
    #
    # @param name [Symbol] The name of the new playlist.
    # @param value [List<Object>] Optional data to initialize the playlist.
    def register(name, value=nil)
      raise 'invalid registry:playlist already registered' unless @data[name].nil?
      @data[name] = value.nil? ? {list: [], idx: -1, repeat: true, shuffled: false} : value
    end

    # Check if a playlist is registered.
    #
    # @param name [Symbol] The name of the new playlist.
    # @return [Boolean] True if previously registered, False otherwise.
    def registered?(name)
      @data.has_key?(name)
    end

    # Creates an interator for all the songs in all the playlists
    #
    # @return [Iterator] Iterator over all the songs.
    def each_song
      idx = 0
      @data.values.each{|info| info[:list].each{|song| yield song, idx += 1 } }
    end

    # Creates an interator for the playlists
    #
    # @return [Iterator] Iterator over the playlists.
    def each
      @data.values.each{|info| yield info[:list] }
    end

    # Check if there is playlists registered.
    #
    # @return [Boolean] True if there is any playlist registered. False otherwise.
    def empty?
      return @data.values.first[:list].empty? if @data.size == 1
      @data.empty?
    end

    # Creates a new playlist object that contains the playlists named in parameters.
    #
    # @return [Playlists] Playlists with selected playlists inside.
    def [](*names)
      validate names
      selected = @data.select{|name,info| names.include?(name) }
      return Playlists.new(selected)
    end

    # Replace the content of the playlist with the content of parameter.
    #
    # @param value [List<Object>] The new contents of the playlist.
    def <=(value)
      @data.keys.each{|name| replace(name, value) }
    end

    # Append the content of the playlist with the content of parameter.
    #
    # @param value [List<Object>] The appended of the playlist.
    def <<(value)
      if value.respond_to?(:each)
        @data.values.each{|info| value.each{|v| info[:list] << v } }
      else
        @data.values.each{|info| info[:list] << value }
      end
    end

    # Removes the last element in the playlists.
    #
    # @return [List<Object>, Object] The las elements in the playlists.
    def pop
      last_ones = collect{|list| list.pop }
      return last_ones.first if last_ones.size == 1
      return last_ones 
    end

    # Shuffle the playlists and reset the indexes.
    def shuffle
      @data.values.each do |info|
        info[:list].shuffle!
        info[:shuffled] = true
        info[:idx] = -1
      end
    end

    # Order the playlists and reset the indexes.
    def order
      @data.values.each do |info|
        info[:list].sort!
        info[:idx] = -1
        info[:shuffled] = false
      end
    end

    # Returns the next song in playlist, which means the new current song.
    #
    # @return [List<Object>,Object] The next element(s) in playlist(s).
    def next
      each_next do |info, nxt_idx|
        info[:idx] = nxt_idx
        info[:list].at nxt_idx
      end
    end

    # Returns the previous song in playlist.
    #
    # @return [List<Object>,Object] The previous element(s) in playlist(s).
    def rewind_by(idx)
      each_next do |info, nxt_idx|
        info[:idx] -= idx
        info[:list].at info[:idx]
      end
    end

    # Remove the next element in playlist.
    #
    # @return [List<Object>,Object] The next element(s) in playlist(s).
    def remove_next
      each_next do |info, nxt_idx|
        info[:list].delete_at nxt_idx
      end
    end

    # Return the play index in the playlists.
    #
    # @return [List<Integer>, Integer] Indexes of the playlists.
    def play_index
      return first_or_map :idx
    end

    # Return the repeat status in the playlists.
    #
    # @return [List<Boolean>, Boolean] Indexes of the playlists.
    def repeat?
      return first_or_map :repeat
    end

    # Change the repeat status in the playlists.
    def repeat(value)
      @data.values.each{|info| info[:repeat] = is_true_value?(value) }
    end

    # Returns the current element in playlists.
    #
    # @return [List<Object>, Object] The current element(s) in playlist(s).
    def current
      currents = @data.values
      .select{|info| info[:idx] >= 0}
      .map do |info|
        info[:list].at info[:idx]
      end

      return nil if currents.empty?
      raise 'no current:no current song in one of the playlists' if @data.size != currents.size
      return currents.first if currents.size == 1
      return currents
    end

    # The number of registered playlists.
    #
    # @return [Integer] The size of registered playlist.
    def size
      @data.size
    end

    # Return a list with all the songs in all the playlists.
    #
    # @return [List<Object>] A list with all the songs in all the playlists.
    def to_a
      @data.values.reduce([]){|acc,info| acc + info[:list]}
    end

    alias :songs :to_a

    # Returns the elements in the playlist.
    #
    # @param idx [Integer] The positional index of the element required.
    # @return [List<Object>, Object] The positional elements in the playlists.
    def at(idx)
      return @data.values.first[:list].at(idx) if @data.size == 1
      return @data.values.collect{|info| info[:list].at(idx) }
    end

    # Returns a string representation of the playlists.
    #
    # @return [String] A representation of the playlists.
    def as_list
      list = ""
      each_song{|s,i| list << "#{i}. #{s.to_s}\n" }
      return list
    end

    # Check if there is another element in playlists.
    #
    # @return [List<Boolean>, Boolean] True if the the playlist has more elements, False otherwise.
    def next?
      nexts = each_next_with_index{|info, nxt_idx| nxt_idx }
      has_nexts = nexts.map{|nxt_idx| !nxt_idx.nil? }
      return has_nexts.first if has_nexts.size == 1
      return has_nexts
    end

    # Check the status of shuffling in playlists.
    #
    # @return [List<Boolean>, Boolean] True if playlist is shuffling. False otherwise.
    def shuffling?
      return first_or_map :shuffled
    end

    private

    def first_or_map(attr)
      return @data.values.first[attr] if @data.size == 1
      return @data.values.map{|info| info[attr] }
    end

    # Returns the non-empty playlists yielded by the block
    def each_next_with_index
      @data.values
      .select{|info| !info[:list].empty? }
      .map do |info|
        nxt_idx = next_idx(info[:idx], info[:list].size, info[:repeat])
        nxt_idx.nil? ? nil : yield(info, nxt_idx)
      end
    end

    # Returns an array with songs, if multiple playlists and only one if single playlist is available
    def each_next(&block)
      nexts = each_next_with_index(&block).compact
      raise "playlist empty:no songs in playlists" if nexts.empty?
      raise "playlist empty:no songs in one of the playlists" if nexts.size != @data.size
      return nexts.first if nexts.size == 1
      return nexts
    end

    def next_idx(actual_idx, size, repeat)
      next_idx = actual_idx + 1
      next_idx = next_idx % size if repeat
      return nil if next_idx >= size
      return next_idx
    end

    def replace(name, value)
      @data[name][:list].replace value
      @data[name][:idx] = -1
    end

    def validate(names)
      raise 'unknown playlist:playlist is not registered' if names.any?{|n| !@data.keys.include?(n) }
    end
  end
end
