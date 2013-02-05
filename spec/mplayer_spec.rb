require "spec_helper"

PATH_3000MS = "spec/3000ms.mp3"
PATH_10000MS = "spec/10000ms.mp3"
NONEXISTANT_PATH = "spec/not_here.mp3"
INVALID_AUDIO_FILE = "spec/invalid.mp3"

describe Plllayer::SinglePlayers::MPlayer do
  before(:each) do
    @player = Plllayer::SinglePlayers::MPlayer.new
  end

  after(:each) do
    @player.stop
  end

  it "is not playing by default" do
    @player.should_not be_playing
  end

  it "starts playing a single audio file" do
    @player.play(PATH_3000MS)
    @player.should be_playing
    sleep 3.1
    @player.should_not be_playing
  end

  it "executes a callback when the track is done playing" do
    done_playing = false
    @player.play(PATH_3000MS) { done_playing = true }
    done_playing.should be_false
    sleep 3.1
    done_playing.should be_true
  end

  it "doesn't play non-existant files" do
    expect { @player.play NONEXISTANT_PATH }.to raise_error(Plllayer::FileNotFoundError)
  end

  it "doesn't play invalid audio files" do
    expect { @player.play INVALID_AUDIO_FILE }.to raise_error(Plllayer::InvalidAudioFileError)
  end

  it "stops playback" do
    callback_called = false
    @player.play(PATH_3000MS) { callback_called = true }
    @player.stop
    @player.should_not be_playing
    sleep 3.1
    callback_called.should be_false
  end

  it "pauses and resumes playback" do
    @player.play(PATH_3000MS)
    @player.should_not be_paused
    @player.pause
    @player.should be_paused
    position = @player.position
    sleep 0.3
    @player.position.should be_within(100).of(position)
    @player.resume
    @player.should_not be_paused
    sleep 0.3
    @player.position.should_not be_within(100).of(position)
  end

  it "seeks to an absolute position" do
    @player.play(PATH_3000MS)
    @player.pause
    @player.seek(2000)
    @player.position.should be_within(100).of(2000)
  end

  it "seeks to a relative position" do
    @player.play(PATH_10000MS)
    @player.pause
    position = @player.position
    @player.seek(5000, :relative)
    @player.position.should be_within(2500).of(position + 5000)
    @player.seek(-4000, :relative)
    @player.position.should be_within(2500).of(position + 1000)
  end

  it "seeks to a percentage position" do
    @player.play(PATH_3000MS)
    @player.pause
    @player.seek(50, :percent)
    @player.position.should be_within(100).of(1500)
  end

  it "has a default speed of 1" do
    @player.speed.should eq(1.0)
  end

  it "speeds up playback" do
    @player.speed = 2.0
    @player.play(PATH_3000MS)
    @player.should be_playing
    sleep 2.5
    @player.should_not be_playing
  end

  it "slows down playback" do
    @player.speed = 0.5
    @player.play(PATH_3000MS)
    @player.should be_playing
    sleep 3.1
    @player.should be_playing
    sleep 3
    @player.should_not be_playing
  end

  it "is not initially muted" do
    @player.should_not be_muted
  end

  it "mutes the volume" do
    @player.mute
    @player.should be_muted
  end

  it "unmutes the volume" do
    @player.mute
    @player.unmute
    @player.should_not be_muted
  end

  it "has a default volume of 50%" do
    @player.volume.should eq(50)
  end

  it "changes the volume" do
    @player.volume = 100
    @player.volume.should eq(100)
  end

  it "unmutes when changing the volume" do
    @player.mute
    @player.volume = 50
    @player.should_not be_muted
  end

  it "keeps track of the position of playback" do
    @player.play(PATH_3000MS)
    @player.position.should be_within(100).of(100)
    sleep 0.5
    @player.position.should be_within(200).of(600)
  end

  it "tells you the length of the track in milliseconds" do
    @player.play(PATH_3000MS)
    @player.track_length.should be_within(100).of(3000)
  end

  it "persists speed, volume, and mute settings from track to track" do
    @player.play(PATH_3000MS)
    @player.speed = 2.0
    @player.volume = 5
    @player.mute
    @player.stop

    @player.play(PATH_3000MS)
    @player.speed.should eq(2.0)
    @player.volume.should eq(5)
    @player.should be_muted
  end

  it "returns false for most commands when playback is stopped" do
    @player.stop.should eq(false)
    @player.pause.should eq(false)
    @player.resume.should eq(false)
    @player.seek(0).should eq(false)
    @player.position.should eq(false)
    @player.track_length.should eq(false)
  end

  it "returns false when double pausing resuming" do
    @player.play(PATH_3000MS)
    @player.pause.should be_true
    @player.pause.should eq(false)
    @player.resume.should be_true
    @player.resume.should eq(false)
  end
end

