class Plllayer
  module SinglePlayers
    # This is the SinglePlayer implementation for mplayer. It requires mplayer
    # to be in your $PATH. It uses open4 to start up and communicate with the
    # mplayer process, and mplayer's slave protocol to issue commands to mplayer.
    class MPlayer < Plllayer::SinglePlayer
      attr_reader :track_path

      # Create a new MPlayer. The mplayer process is only started when the #play
      # method is called to start playing a song. The process quits when the
      # song ends. Even though a new process is started for each song, the
      # MPlayer object keeps track of the volume, speed, and mute properties and
      # sets these properties when a new song is played.
      def initialize
        @paused = false
        @muted = false
        @volume = 50
        @speed = 1.0
        @track_path = nil
      end

      def playing?
        not @track_path.nil?
      end

      def play(track_path, &on_end)
        # Make sure we're only playing one song at any one time.
        _quit

        if File.exists? track_path
          # Run the mplayer process in slave mode, passing it the location of
          # the track's audio file.
          cmd = ["mplayer", "-slave", "-quiet", track_path]
          @pid, @stdin, @stdout, @stderr = Open4.popen4(*cmd)

          # This should skip past mplayer's initial lines of output so we can
          # start reading its replies to our commands.
          until @stdout.gets["playback"]
          end

          @paused = false
          @track_path = track_path

          # Persist the previous speed, volume, and mute properties into this
          # process.
          self.speed = @speed
          self.volume = @volume
          mute if @muted

          # Start a thread that waits for the mplayer process to end, then calls
          # the end of song callback. If the #quit method is called, this thread
          # will be killed if it's still waiting for the process to end.
          @quit_hook_active = false
          @quit_hook = Thread.new do
            Process.wait(@pid)
            @quit_hook_active = true
            @paused = false
            @track_path = nil
            on_end.call
          end

          true
        else
          false
        end
      end

      def stop
        _quit
      end

      def pause
        if not @paused
          @paused = true
          _command "pause"
        else
          false
        end
      end

      def resume
        if @paused
          @paused = false
          _command "pause"
        else
          false
        end
      end

      def seek(where, type = :absolute)
        # mplayer talks seconds, not milliseconds.
        seconds = where.to_f / 1_000
        case type
        when :absolute
          _command "seek #{seconds} 2", expect_answer: true
        when :relative
          _command "seek #{seconds} 0", expect_answer: true
        when :percent
          _command "seek #{where} 1", expect_answer: true
        else
          raise NotImplementedError
        end
      end

      def speed
        @speed
      end

      def speed=(new_speed)
        @speed = new_speed.to_f
        answer = _command "speed_set #{@speed}", expect_answer: true
        !!answer
      end

      def muted?
        @muted
      end

      def mute
        @muted = true
        answer = _command "mute 1", expect_answer: true
        !!answer
      end

      def unmute
        @muted = false
        answer = _command "mute 0", expect_answer: true
        !!answer
      end

      def volume
        @volume
      end

      def volume=(new_volume)
        @muted = false
        @volume = new_volume.to_f
        answer = _command "volume #{@volume} 1", expect_answer: true
        !!answer
      end

      def position
        answer = _command "get_time_pos", expect_answer: /^ANS_TIME_POSITION=([0-9.]+)$/
        answer ? (answer.to_f * 1000).to_i : false
      end

      def track_length
        answer = _command "get_time_length", expect_answer: /^ANS_LENGTH=([0-9.]+)$/
        answer ? (answer.to_f * 1000).to_i : false
      end

      private

      # Issue a command to mplayer through the slave protocol. False is returned
      # if the process is dead (not playing anything).
      #
      # If the :expect_answer option is set to true, this will wait for a legible
      # answer back from mplayer, and send it as a return value. If :expect_answer
      # is set to a Regexp, the answer mplayer gives back will be matched to that
      # Regexp and the first match will be returned. If there are no matches, nil
      # will be returned.
      def _command(cmd, options = {})
        if _alive? and playing?
          # If the player is paused, prefix the command with "pausing ".
          # Otherwise it unpauses when it runs a command. The only exception to
          # this is when the "pause" command itself is issued.
          if @paused and cmd != "pause"
            cmd = "pausing #{cmd}"
          end

          # Send the command to mplayer.
          @stdin.puts cmd

          if options[:expect_answer]
            # Read lines of output from mplayer until we get an actual message.
            answer = "\n"
            while answer == "\n"
              answer = @stdout.gets.sub("\e[A\r\e[K", "")
              answer = "\n" if options[:expect_answer].is_a?(Regexp) && answer !~ options[:expect_answer]
            end

            if options[:expect_answer].is_a? Regexp
              matches = answer.match(options[:expect_answer])
              answer = matches && matches[1]
            end

            answer
          else
            true
          end
        else
          false
        end
      end

      # Quit the mplayer process, stopping playback. The end of song callback
      # will not be called if this method is called.
      def _quit
        if _alive?
          @quit_hook.kill unless @quit_hook_active
          _command "quit"
          @paused = false
          @track_path = nil
        end
        true
      end

      # Check if the mplayer process is still around.
      def _alive?
        return false if @pid.nil?
        Process.getpgid(@pid)
        true
      rescue Errno::ESRCH
        false
      end
    end
  end
end
