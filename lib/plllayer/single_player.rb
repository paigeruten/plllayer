class Plllayer
  # Raise this exception when the file at the given track path doesn't exist.
  FileNotFoundError = Class.new(ArgumentError)

  # Raise this one when the file can't be played for whatever reason
  InvalidAudioFileError = Class.new(ArgumentError)

  # A SinglePlayer takes care of playing a single track, and controlling the
  # playback with commands like pause, resume, seek, and so on. It probably
  # starts an external audio player process to do this job. This class is an
  # interface that is to be implemented for different audio players. Then the
  # user can choose which SinglePlayer to use based on what audio players they
  # have installed.
  #
  # All methods that perform an action should return false if the action isn't
  # applicable, and return a truthy value otherwise.
  class SinglePlayer
    # Return true if a track is currently loaded, i.e. either playing or
    # paused.
    def playing?
      raise NotImplementedError
    end

    # Get the current track path which was passed to the play method.
    def track_path
      raise NotImplementedError
    end

    # Begin playing a track. The track_path should be a String representing a
    # path to an audio file. The &on_end callback should be called when the track
    # is finished playing. Should raise FileNotFoundError if the audio file
    # doesn't exist.
    def play(track_path, &on_end)
      raise NotImplementedError
    end

    # Stop playback.
    def stop
      raise NotImplementedError
    end

    # Pause playback.
    def pause
      raise NotImplementedError
    end

    # Resume playback.
    def resume
      raise NotImplementedError
    end

    # Seek to a particular position in the track. Different types can be
    # supported, such as absolute, relative, or percent. All times are specified
    # in milliseconds. A NotImplementedError should be raised when a certain type
    # isn't supported.
    def seek(where, type = :absolute)
      case type
      when :absolute
        raise NotImplementedError
      when :relative
        raise NotImplementedError
      when :percent
        raise NotImplementedError
      else
        raise NotImplementedError
      end
    end

    # Get the current playback speed. The speed is a multiplier. For example,
    # double speed is 2 and half-speed is 0.5. Normal speed is 1.
    def speed
      raise NotImplementedError
    end

    # Set the playback speed. The speed is a multiplier. For example, for
    # double speed you'd set it to 2 and for half-speed you'd set it to 0.5. And
    # for normal speed: 1.
    def speed=(new_speed)
      raise NotImplementedError
    end

    # Return true if audio is muted.
    def muted?
      raise NotImplementedError
    end

    # Mute the audio player.
    def mute
      raise NotImplementedError
    end

    # Unmute the audio player.
    def unmute
      raise NotImplementedError
    end

    # Get the current volume as a percentage.
    def volume
      raise NotImplementedError
    end

    # Set the volume as a percentage. The player may be automatically unmuted.
    def volume=(new_volume)
      raise NotImplementedError
    end

    # Return the current time into the song, in milliseconds.
    def position
      raise NotImplementedError
    end

    # Return the length of the current track, in milliseconds.
    def track_length
      raise NotImplementedError
    end
  end
end
