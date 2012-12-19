require "open4"

require "plllayer/single_player"
require "plllayer/single_players/mplayer"

class Plllayer
  attr_reader :repeat_mode

  def initialize(*args)
    options = {}
    options = args.pop if args.last.is_a? Hash

    @single_player = Plllayer::SinglePlayers::MPlayer.new
    @playlist = []
    append(args.first) unless args.empty?
    @index = nil
    @paused = false
    @playing = false
    @repeat_mode = nil

    at_exit { stop }
  end

  def append(tracks)
    tracks = Array(tracks).dup
    tracks.select! { |track| track.respond_to?(:location) || (track.is_a?(String) && File.exists?(track)) }
    @playlist += tracks
    @playlist.dup
  end
  alias :<< :append

  def playlist
    @playlist.dup
  end

  def track
    @index ? @playlist[@index] : nil
  end

  def track_index
    @index
  end

  def track_path
    if track.respond_to? :location
      track.location
    else
      track
    end
  end

  def clear
    stop
    @playlist.clear
    true
  end

  def paused?
    @paused
  end

  def playing?
    @playing
  end

  def play
    unless @playlist.empty?
      @playing = true
      @paused = false
      @index = 0
      play_track
      true
    else
      false
    end
  end

  def stop
    @single_player.stop
    @track = nil
    @index = nil
    @paused = false
    @playing = false
    true
  end

  def pause
    if playing?
      @paused = true
      @single_player.pause
    else
      false
    end
  end

  def resume
    if playing?
      @paused = false
      if @single_player.playing?
        @single_player.resume
      else
        play_track @track
        @playlist_paused = false
        true
      end
    else
      false
    end
  end

  def repeat(one_or_all_or_off)
    case one_or_all_or_off
    when :one
      @repeat_mode = :one
    when :all
      @repeat_mode = :all
    when :off
      @repeat_mode = nil
    end
    true
  end

  def restart
    change_track(0)
  end

  def back(n = 1)
    change_track(-n)
  end

  def skip(n = 1)
    change_track(n)
  end

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
      @single_player.seek(parse_time(where), :absolute)
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
    end
  end

  def speed
    @single_player.speed || 1.0
  end

  def speed=(new_speed)
    @single_player.speed = new_speed
  end

  def mute
    @single_player.mute
  end

  def unmute
    @single_player.unmute
  end

  def muted?
    @single_player.muted?
  end

  def volume
    @single_player.volume
  end

  def volume=(new_volume)
    @single_player.volume = new_volume
  end

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

  def sort(&by)
    current_track = track
    @playlist.sort! &by
    if playing?
      @index = @playlist.index(current_track)
    end
    true
  end

  def position
    @single_player.position || 0
  end

  def formatted_position(options = {})
    format_time(position, options)
  end

  def track_length
    if paused? && !@single_player.playing?
      resume
      pause
    end
    @single_player.track_length
  end

  def formatted_track_length(options = {})
    if length = track_length
      format_time(length, options)
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

  # Helper method to format a number of milliseconds as a string like
  # "1:03:56.555". The only option is :include_milliseconds, true by default. If
  # false, milliseconds won't be included in the formatted string.
  def format_time(milliseconds, options = {})
    ms = milliseconds % 1000
    seconds = (milliseconds / 1000) % 60
    minutes = (milliseconds / 60000) % 60
    hours = milliseconds / 3600000

    if ms.zero? || options[:include_milliseconds] == false
      ms_string = ""
    else
      ms_string = ".%03d" % [ms]
    end

    if hours > 0
      "%d:%02d:%02d%s" % [hours, minutes, seconds, ms_string]
    else
      "%d:%02d%s" % [minutes, seconds, ms_string]
    end
  end

  # Helper method to parse a string like "1:03:56.555" and return the number of
  # milliseconds that time length represents.
  def parse_time(string)
    parts = string.split(":").map(&:to_f)
    parts = [0] + parts if parts.length == 2
    hours, minutes, seconds = parts
    seconds = hours * 3600 + minutes * 60 + seconds
    milliseconds = seconds * 1000
    milliseconds.to_i
  end
end

