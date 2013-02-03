class Plllayer
  module SinglePlayers
    # This is the SinglePlayer implentation used for testing. It doesn't actually
    # do anything, it just pretends to play a music file using sleeps.
    class Nop < Plllayer::SinglePlayer
      attr_reader :track_path

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
        _quit

        # Make sure the audio file exists.
        raise FileNotFoundError, "file '#{track_path}' doesn't exist" unless File.exists? track_path

        @paused = false
        @track_path = track_path

        # Assume the filename starts with the song length in milliseconds, so we
        # don't actually have to read the file.
        @total_time = File.basename(@track_path, ".*").to_i
        @time_left = @total_time
        @last_tick = Time.now

        @quit_hook_active = false
        @quit_hook = Thread.new do
          while @time_left > 0
            unless @paused
              @time_left -= ((Time.now - @last_tick) * 1000 * @speed).to_i
            end
            @last_tick = Time.now
            sleep 0.01
          end
          @quit_hook_active = true
          @paused = false
          @track_path = nil
          @started = nil
          on_end.call
        end

        true
      end

      def stop
        _quit
      end

      def paused?
        @paused
      end

      def pause
        if not @paused and playing?
          @paused = true
        else
          false
        end
      end

      def resume
        if @paused
          @paused = false
          true
        else
          false
        end
      end

      def seek(where, type = :absolute)
        if playing?
          case type
          when :absolute
            @time_left = @total_time - where
          when :relative
            @time_left -= where
          when :percent
            @time_left = @total_time - (@total_time * where) / 100
          end
          true
        else
          false
        end
      end

      def speed
        @speed
      end

      def speed=(new_speed)
        @speed = new_speed.to_f
        true
      end

      def muted?
        @muted
      end

      def mute
        @muted = true
      end

      def unmute
        @muted = false
        true
      end

      def volume
        @volume
      end

      def volume=(new_volume)
        @muted = false
        @volume = new_volume.to_f
        true
      end

      def position
        playing? ? @total_time - @time_left : false
      end

      def track_length
        playing? ? @total_time : false
      end

      private

      def _quit
        if playing?
          @quit_hook.kill unless @quit_hook_active
          @paused = false
          @track_path = nil
          true
        else
          false
        end
      end
    end
  end
end
