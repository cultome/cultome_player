require 'cultome_player/utils'

module CultomePlayer::Player::Playlist
  def playlists
    @playlists ||= Playlists.new
  end

  def playlist?(name)
    playlists.registered?(name)
  end

  class Playlists
    include Enumerable
    include CultomePlayer::Utils

    def initialize(data=nil)
      @data = {}
      data.each{|arr| register(*arr) } unless data.nil?
    end

    def registered?(name)
      @data.has_key?(name)
    end

    def each_song
      @data.values.each{|info| info[:list].each{|song| yield song } }
    end

    def each
      @data.values.each{|info| yield info[:list] }
    end

    def empty?
      return @data.values.first[:list].empty? if @data.size == 1
      @data.empty?
    end

    def [](*names)
      validate names
      selected = @data.select{|name,info| names.include?(name) }
      return Playlists.new(selected)
    end

    def <=(value)
      @data.keys.each{|name| replace(name, value) }
    end

    def <<(value)
      if value.respond_to?(:each)
        @data.values.each{|info| value.each{|v| info[:list] << v } }
      else
        @data.values.each{|info| info[:list] << value }
      end
    end

    def register(name, value=nil)
      raise 'invalid registry:playlist already registered' unless @data[name].nil?
      @data[name] = value.nil? ? {list: [], idx: -1, repeat: true} : value
    end

    def shuffle
      @data.values.each do |info|
        info[:list].shuffle!
        info[:idx] = -1
      end
    end

    def order
      @data.values.each do |info|
        info[:list].sort!
        info[:idx] = -1
      end
    end

    def next
      each_next do |info, nxt_idx|
        info[:idx] = nxt_idx 
        info[:list].at nxt_idx
      end
    end

    def remove_next
      each_next do |info, nxt_idx|
        info[:list].delete_at nxt_idx 
      end
    end

    def play_index
      return first_or_map :idx
    end

    def repeat?
      return first_or_map :repeat
    end

    def repeat(value)
      @data.values.each{|info| info[:repeat] = is_true_value?(value) }
    end

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

    def size
      @data.size
    end

    def to_a
      @data.values.reduce([]){|acc,info| acc + info[:list]}
    end

    alias :songs :to_a

    def at(idx)
      return @data.values.first[:list].at(idx) if @data.size == 1
      return @data.values.collect{|info| info[:list].at(idx) }
    end

    private

    def first_or_map (attr)
      return @data.values.first[attr] if @data.size == 1
      return @data.values.map{|info| info[attr] }
    end

    def each_next
      nexts = @data.values
      .select{|info| !info[:list].empty? }
      .map do |info|
        nxt_idx = next_idx(info[:idx], info[:list].size, info[:repeat])
        yield(info, nxt_idx)
      end

      raise "playlist empty:no songs in playlists" if nexts.empty?
      raise "playlist empty:no songs in one of the playlists" if nexts.size != @data.size
      return nexts.first if nexts.size == 1
      return nexts
    end

    def next_idx(actual_idx, size, repeat)
      next_idx = actual_idx + 1
      next_idx = next_idx % size if repeat
      raise 'end of playlist:no more song in the playlist' if next_idx >= size
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
