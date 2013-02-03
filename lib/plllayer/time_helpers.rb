class Plllayer
  module TimeHelpers
    # Helper method to format a number of milliseconds as a string like
    # "1:03:56.555". The only option is :include_milliseconds, true by default. If
    # false, milliseconds won't be included in the formatted string.
    def format_time(milliseconds, options = {})
      raise ArgumentError, "can't format negative time" if milliseconds < 0

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
      parts = string.split(":", -1).map(&:to_f)

      raise ArgumentError, "too many parts" if parts.length > 3
      raise ArgumentError, "can't parse negative numbers" if parts.any? { |x| x < 0 }

      parts.unshift(0) until parts.length == 3
      hours, minutes, seconds = parts
      seconds = hours * 3600 + minutes * 60 + seconds
      milliseconds = seconds * 1000
      milliseconds.to_i
    end
  end
end

