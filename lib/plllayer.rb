require "open4"

require "plllayer/time_helpers.rb"
require "plllayer/single_player"
require "plllayer/single_players/mplayer"
require "plllayer/single_players/nop"

# Plllayer provides an interface to an external media player, such as mplayer. It
# contains a playlist of tracks, which may be as simple as an Array of paths to
# some audio files. You can then control the playback of this playlist by calling
# various command-like methods, like play, pause, seek, skip, shuffle, and so on.
class Plllayer
  # This pulls in the Plllayer.parse_time and Plllayer.format_time helper methods.
  # See plllayer/time_helpers.rb.
  extend TimeHelpers

  SINGLE_PLAYERS = {
    mplayer: Plllayer::SinglePlayers::MPlayer,
    nop: Plllayer::SinglePlayers::Nop
  }

  attr_reader :repeat_mode

  # Create a new Plllayer. Optionally, you can pass in an initial playlist to be
  # loaded (won't start playing until you call #play). You can also pass the
  # :external_player option to specify the preferred external player to use.
  # Otherwise, it will try to figure out what external players are available, and
  # attempt to use the best one available.
  #
  # However, only mplayer is supported at the moment, so this option isn't useful
  # right now.
  #
  # TODO: check if external player is available before trying to use it.
  def initialize(*args)
    options = {}
    options = args.pop if args.last.is_a? Hash
    options[:external_player] ||= :mplayer

    # Look up the single player class, raise error if it doesn't exist.
    single_player_class = SINGLE_PLAYERS[options[:external_player].to_sym]
    if single_player_class.nil?
      raise NotImplementedError, "external player #{options[:external_player]} not supported"
    end

    @single_player = single_player_class.new
    @playlist = []
    append(args.first) unless args.empty?
    @index = nil
    @paused = false
    @playing = false
    @repeat_mode = nil
  end

  # Append tracks to the playlist. Can be done while the playlist is playing.
  # A track is either a String containing the path to the audio file, or an
  # object with a #location method that returns the path to the audio file.
  # An ArgumentError is raised when you try to pass a non-track.
  #
  # This method is aliased as the << operator.
  def append(tracks)
    tracks = Array(tracks)
    tracks.each do |track|
      if !track.is_a?(String) && !track.respond_to?(:location)
        raise ArgumentError, "a #{track.class} is not a track (try adding a #location method)"
      end
    end
    @playlist += tracks
    @playlist.dup
  end
  alias :<< :append

  # Returns a copy of the playlist.
  def playlist
    @playlist.dup
  end

  # Get the currently-playing track, or the track that's about to play if
  # you're paused between tracks. Returns nil if playback is stopped.
  def track
    @index ? @playlist[@index] : nil
  end

  # Get the index of the currently-playing track, or of the track that's
  # about to play if you're paused between tracks. Returns nil if playback
  # is stopped.
  def track_index
    @index
  end

  # Get the path to the audio file of the currently-playing track.
  def track_path
    if track.respond_to? :location
      track.location
    else
      track
    end
  end

  # Stop playback and empty the playlist.
  def clear
    stop
    @playlist.clear
    true
  end

  # Check if playback is paused.
  def paused?
    @paused
  end

  # Check if the playlist is being played. Whether playback is paused doesn't
  # affect this. False is only returned if either (1) #play was never called,
  # (2) #stop has been called, or (3) playback stopped after finishing playing
  # all the songs.
  def playing?
    @playing
  end

  # Start playing the playlist from beginning to end.
  def play
    if !@playlist.empty? && !playing?
      @playing = true
      @paused = false
      @index = 0
      play_track
      true
    else
      false
    end
  end

  # Stop playback.
  def stop
    if playing?
      @single_player.stop
      @track = nil
      @index = nil
      @paused = false
      @playing = false
      true
    else
      false
    end
  end

  # Pause playback.
  def pause
    if playing? && !paused?
      @paused = true
      @single_player.pause
    else
      false
    end
  end

  # Resume playback.
  def resume
    if playing? && paused?
      @paused = false
      if @single_player.playing?
        @single_player.resume
      else
        play_track @track
        true
      end
    else
      false
    end
  end

  # Set the repeat behaviour of the playlist. There are three possible values:
  #
  #   :one    repeat a single track over and over
  #   :all    repeat the whole playlist, treating it like a circular array
  #   :off    play songs consecutively, stop playback when done
  #
  # The default, of course, is :off.
  def repeat(one_or_all_or_off)
    case one_or_all_or_off
    when :one
      @repeat_mode = :one
    when :all
      @repeat_mode = :all
    when :off
      @repeat_mode = nil
    else
      raise ArgumentError
    end
    true
  end

  # Play the currently-playing track from the beginning.
  def restart
    change_track(0)
  end

  # Play the previous track. Pass a number to go back that many tracks. Treats
  # the playlist like a circular array if the repeat mode is :all.
  def back(n = 1)
    change_track(-n)
  end

  # Play the next track. Pass a number to go forward that many tracks. Treats
  # the playlist like a circular array if the repeat mode is :all.
  def skip(n = 1)
    change_track(n)
  end

  # Seek to a particular position within the currently-playing track. There are
  # multiple ways to specify where to seek to:
  #
  #   seek 10000         # seek 10000 milliseconds forward, relative to the current position
  #   seek -5000         # seek 5000 milliseconds backward
  #   seek "3:45"        # seek to the absolute position 3 minutes and 45 seconds
  #   seek "1:03:45.123" # seek to 1 hour, 3 minutes, 45 seconds, 123 milliseconds
  #   seek 3..45         # syntax sugar for seeking to "3:45"
  #   seek 3..45.123     # syntax sugar for seeking to "3:45.123"
  #   seek abs: 150000   # seek to the absolute position 150000 milliseconds
  #   seek percent: 80   # seek to 80% of the way through the track
  #
  def seek(where)
    if paused? && !@single_player.playing?
      resume
      pause
    end

    case where
    when Integer
      @single_player.seek(where, :relative)
    when Range
      seconds = where.begin * 60 + where.end
      @single_player.seek(seconds * 1000, :absolute)
    when String
      @single_player.seek(Plllayer.parse_time(where), :absolute)
    when Hash
      if where[:abs]
        if where[:abs].is_a? Integer
          @single_player.seek(where[:abs], :absolute)
        else
          seek(where[:abs])
        end
      elsif where[:percent]
        @single_player.seek(where[:percent], :percent)
      end
    else
      raise ArgumentError, "seek doesn't take a #{where.class}"
    end
  end

  # Get the playback speed as a Float. 1.0 is normal speed, 2.0 is double speed,
  # 0.5 is half-speed, and so on.
  def speed
    @single_player.speed || 1.0
  end

  # Set the playback speed as a Float. 1.0 is normal speed, 2.0 is double speed,
  # 0.5 is half-speed, and so on.
  def speed=(new_speed)
    @single_player.speed = new_speed
  end

  # Mute the volume.
  def mute
    @single_player.mute
  end

  # Unmute the volume.
  def unmute
    @single_player.unmute
  end

  # Check if volume is muted.
  def muted?
    @single_player.muted?
  end

  # Get the volume, as a percentage.
  def volume
    @single_player.volume
  end

  # Set the volume, as a percentage.
  def volume=(new_volume)
    @single_player.volume = new_volume
  end

  # Shuffle the playlist. If this is done while the playlist is playing, the
  # current song will go to the top of the playlist and the rest of the songs
  # will be shuffled.
  def shuffle
    current_track = track
    @playlist.shuffle!
    if playing?
      index = @playlist.index(current_track)
      @playlist[0], @playlist[index] = @playlist[index], @playlist[0]
      @index = 0
    end
    true
  end

  # Sorts the playlist. Delegates to Array#sort, so a block may be passed to
  # specify what the tracks should be sorted by.
  #
  # This method is safe to call while the playlist is playing.
  def sort(&by)
    current_track = track
    @playlist.sort! &by
    if playing?
      @index = @playlist.index(current_track)
    end
    true
  end

  # Returns the current position of the currently-playing track, in milliseconds.
  def position
    @single_player.position || 0
  end

  # Returns the current position of the currently-playing track, as a String
  # like "1:23".
  def formatted_position(options = {})
    Plllayer.format_time(position, options)
  end

  # Returns the length of the currently-playing track, in milliseconds.
  def track_length
    if paused? && !@single_player.playing?
      resume
      pause
    end
    @single_player.track_length
  end

  # Returns the length of the currently-playing track, as a String like "1:23".
  def formatted_track_length(options = {})
    if length = track_length
      Plllayer.format_time(length, options)
    end
  end

  private

  def change_track(by = 1, options = {})
    if playing?
      if options[:auto] && track.respond_to?(:increment_play_count)
        track.increment_play_count
      end
      @index += by
      if @repeat_mode
        case @repeat_mode
        when :one
          @index -= by if options[:auto]
        when :all
          @index %= @playlist.length
        end
      end
      if track && @index >= 0
        @single_player.stop if paused? && @single_player.active?
        play_track if not paused?
      else
        stop
      end
      true
    else
      false
    end
  end

  def play_track
    @single_player.play(track_path) do
      change_track(1, auto: true)
      ActiveRecord::Base.connection.close if defined?(ActiveRecord)
    end
    @paused = false
    true
  end
end

