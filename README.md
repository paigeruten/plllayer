# plllayer

`plllayer` provides a Ruby interface to an external media player, such as `mplayer`.

It takes a playlist to play (which may just be an `Array` of `String`s containing the paths to the audio files), and lets you control playback as the playlist plays, with commands such as `pause`, `resume`, `seek`, `skip`, and so on.

## Install

```bash
$ gem install plllayer
```

## Example

Here's how to play your music library in random order:

```bash
$ irb
irb> require "plllayer"
  => true
irb> player = Plllayer.new(Dir["Music/**/*.{mp3,m4a,ogg}"])
  => #<Plllayer: ... >
irb> player.shuffle
  => true
irb> player.play
  => true
irb>
```

Then, while it's playing, you can type `player.track` to see what song it's playing, `player.skip` to skip to the next song, and so on.

## Usage

Make a `Plllayer` like this:

```ruby
player = Plllayer.new
```

This initializes a `Plllayer` with an empty playlist, and will use whatever external audio player is available on the system. You can also pass in an initial playlist, or specify what external audio player you want to use:

```ruby
player = Plllayer.new(playlist)
player = Plllayer.new(external_player: :mplayer)
```

Only `mplayer` is supported at the moment.

### Playlists

A playlist is just an `Array` of tracks. A track is either a `String` containing the path to an audio file, or an object with a `#location` attribute that returns the path.

A singleton playlist, with only one track, doesn't need to be in an `Array`. That's ugly. You can just pass a track object to any method that expects a playlist and it'll understand.

To tell the `Plllayer` what playlist to play, either initialize the `Plllayer` with the playlist or use `Plllayer#append`:

```ruby
player = Plllayer.new
player.append(playlist)
player << more_tracks    # the << operator is an alias for append
```

The playlist can be accessed by `Plllayer#playlist`.

The playlist can be shuffled using `Plllayer#shuffle`:

```ruby
player.shuffle
```

If one of the tracks is currently playing, it will be kept at the top of the playlist while the rest of the tracks will be shuffled.

The playlist can also be sorted:

```ruby
player.sort
```

This delegates to Ruby's `Array#sort`, which sorts the tracks using their `<=>` method. This also means you can pass a block to compare tracks by, like this:

```ruby
player.sort { |a, b| [a.artist, a.album, a.track_number] <=> [b.artist, b.album, b.track_number] }
```

This is safe to do when a track is currently playing, and then the next track that plays will be whatever comes next in the sorted playlist.

Lastly, the player's playlist can be reset to an empty playlist using `Plllayer#clear`:

```ruby
player.clear
```

This stops playback if it's currently playing.

### Playback commands

There are many commands that influence playback. Think of them as buttons on a physical media player: you can push them even when they don't apply to the state of the player. They always return false if this is the case, otherwise they return a truthy value.

See `lib/plllayer.rb` for all the available commands, with documentation.

## Todo

* Support multiple external players
* Work around mplayer's bug where it reports the length of the track totally wrong
* Fix bug with mplayer returning weird answers sometimes
* Write tests

