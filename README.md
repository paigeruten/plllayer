Note: I'm currently rethinking this project a bit, so the code, the ruby gem, and this document may not be consistent with each other for a little while.

# plllayer

`plllayer` provides a Ruby interface to an external media player, such as `mplayer`.

It takes a playlist to play (which may just be an `Array` of `String`s containing the paths to the audio files), and lets you control playback as the playlist plays, with commands such as `pause`, `resume`, `seek`, `skip`, and so on.

## Install

    $ gem install plllayer

## Usage

Make a `Plllayer` like this:

    player = Plllayer.new

This initializes a `Plllayer` with an empty playlist, and will use whatever external audio player is available on the system. You can also pass in an initial playlist, or specify what external audio player you want to use:

    player = Plllayer.new(playlist)
    player = Plllayer.new(external_player: :mplayer)

Only `mplayer` is supported at the moment.

### Playlists

A playlist is just an `Array` of tracks. A track is either a `String` containing the path to an audio file, or an object with a `#location` attribute that returns the path.

A singleton playlist, with only one track, doesn't need to be in an `Array`. That's ugly. You can just pass a track object to any method that expects a playlist and it'll understand.

To tell the `Plllayer` what playlist to play, either initialize the `Plllayer` with the playlist or use `Plllayer#append`:

    player = Plllayer.new
    player.append(playlist)
    player << more_tracks    # the << operator is an alias for append

The playlist can be accessed by `Plllayer#playlist`.

The playlist can be shuffled using `Plllayer#shuffle`:

    player.shuffle

If one of the tracks is currently playing, it will be kept at the top of the playlist while the rest of the tracks will be shuffled.

The playlist can also be sorted:

    player.sort

This delegates to Ruby's `Array#sort`, which sorts the tracks using their `<=>` method. This also means you can pass a block to compare tracks by, like this:

    player.sort { |a, b| [a.artist, a.album, a.track_number] <=> [b.artist, b.album, b.track_number] }

This is safe to do when a track is currently playing, and then the next track that plays will be whatever comes next in the sorted playlist.

Lastly, the player's playlist can be reset to an empty playlist using `Plllayer#clear`:

    player.clear

This stops playback if it's currently playing.

### Playback commands

There are many commands that influence playback. Think of them as buttons on a physical media player: you can push them even when they don't apply to the state of the player. They always return false if this is the case, otherwise they return a truthy value.

#### play

Starts playing the loaded playlist from the beginning.

    player.play

#### stop

Stops playback. (Cannot be resumed.)

    player.stop

#### playing?

Checks if the playlist has started playing. Returns false when playback has stopped, or was never started. (Doesn't care whether playback is paused or not.)

    is_playing = player.playing?

#### pause

Pauses playback. Commands like `seek` and `skip` may be used while playback is paused.

    player.pause

#### resume

Resumes playback when paused. This is the only way to unpause. (Don't try to use `play` to resume.)

    player.resume

#### paused?

Checks if playback is currently paused.

    is_paused = player.paused?

#### restart

Seeks to the beginning of the current track.

    player.restart

#### back

Goes to the previous track in the playlist. (Stops playback if there is no previous track.)

    player.back
    player.back 5   # go back 5 tracks

#### skip

Goes to the next track in the playlist. (Stops playback if there is no next track.)

    player.skip
    player.skip 5   # skip 5 tracks ahead

#### track

Gets the currently playing track object.

    current_track = player.track

#### track_index

Gets the position of the currently playing track in the playlist. The first track in the playlist has an index of 0, the second one is 1, and so on.

    index = player.track_index

#### repeat

Sets the repeat mode of the player. If set to `:all`, the player will keep replaying the playlist whenever it reaches the end, and `back` and `skip` will treat the playlist like a circular array. If set to `:one`, the current track will keep replaying whenever it ends, and `back` and `skip` aren't affected. If set to `:none`, the player will go back to its default behaviour.

    player.repeat :all
    player.repeat :one
    player.repeat :none

#### repeat_mode

Gets the repeat mode of the player. Either `:all`, `:one`, or `nil`.

    repeat_mode = player.repeat_mode

#### seek

Seeks to a particular position in the current track. The position to seek to can be specified in many ways:

    player.seek 10000         # seek 10000 milliseconds forward, relative to the current position
    player.seek -5000         # seek 5000 milliseconds backward
    player.seek "3:45"        # seek to the absolute position 3 minutes and 45 seconds
    player.seek "1:03:45.123" # seek to 1 hour, 3 minutes, 45 seconds, 123 milliseconds
    player.seek 3..45         # syntax sugar for seeking to "3:45"
    player.seek 3..45.123     # syntax sugar for seeking to "3:45.123"
    player.seek abs: 150000   # seek to the absolute position 150000 milliseconds
    player.seek percent: 80   # seek to 80% of the way through the track

#### position

Gets the current position in the currently playing track, in milliseconds.

    current_time = player.position

#### formatted_position

Gets the current position in the currently playing track as a user-friendly string, like `"3:45.123"`. If you don't want the milliseconds, pass `include_milliseconds: false` as an option. If the milliseconds are 0, they won't be shown either way.

    formatted_current_time = player.formatted_position
    formatted_current_time = player.formatted_position(include_milliseconds: false)

#### track_length

Gets the length of the currently playing track, in milliseconds.

    length = player.track_length

#### formatted_track_length

Gets the length of the currently playing track as a user-friendly string, like `"3:45.123"`. If you don't want the milliseconds, pass `include_milliseconds: false` as an option. If the milliseconds are 0, they won't be shown either way.

    formatted_length = player.formatted_track_length
    formatted_length = player.formatted_track_length(include_milliseconds: false)

#### speed=

Sets the current speed of playback, as a multiplier. Normal speed is 1.0, double speed is 2.0, half speed is 0.5, and so on.

    player.speed = 2

#### speed

Gets the current speed of playback, as a multiplier.

    speed = player.speed

#### mute

Mutes audio.

    player.mute

#### unmute

Unmutes audio.

    player.unmute

#### muted?

Checks if audio is currently muted.

    muted = player.muted?

#### volume=

Sets the volume as a percentage. May automatically unmute the audio.

    player.volume = 50

#### volume

Gets the volume as a percentage.

    vol = player.volume

## Todo

* Support multiple external players
* Make Plllayer's instance methods' return values more consistent
* Better error reporting
* Work around mplayer's bug where it reports the length of the track totally wrong
* Fix bug with mplayer returning weird answers sometimes
* Write tests, documentation

