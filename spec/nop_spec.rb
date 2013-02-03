require "spec_helper"

PATH = "spec/250ms.mp3"
NONEXISTANT_PATH = "spec/not_here.mp3"

describe Plllayer::SinglePlayers::Nop do
  before(:each) do
    @player = Plllayer::SinglePlayers::Nop.new
  end

  it "is not playing by default" do
    @player.should_not be_playing
  end

  it "starts playing a single audio file" do
    @player.play PATH
    @player.should be_playing
    sleep 0.5
    @player.should_not be_playing
  end

  it "executes a callback when the track is done playing" do
    done_playing = false
    @player.play(PATH) { done_playing = true }
    done_playing.should be_false
    sleep 0.5
    done_playing.should be_true
  end

  it "doesn't play non-existant files" do
    expect { @player.play NONEXISTANT_PATH }.to raise_error(Plllayer::FileNotFoundError)
  end

  it "stops playback" do
    callback_called = false
    @player.play(PATH) { callback_called = true }
    @player.stop
    @player.should_not be_playing
    sleep 0.5
    callback_called.should be_false
  end

  it "pauses and resumes playback" do
    @player.play(PATH)
    @player.should_not be_paused
    @player.pause
    @player.should be_paused
    position = @player.position
    sleep 0.2
    @player.position.should eq(position)
    @player.resume
    @player.should_not be_paused
    sleep 0.2
    @player.position.should_not eq(position)
  end

  it "seeks to an absolute position" do
    @player.play(PATH)
    @player.pause
    @player.seek(100)
    @player.position.should eq(100)
  end

  it "seeks to a relative position" do
    @player.play(PATH)
    @player.pause
    position = @player.position
    @player.seek(10, :relative)
    @player.position.should eq(position + 10)
    @player.seek(-10, :relative)
    @player.position.should eq(position)
  end

  it "seeks to a percentage position" do
    @player.play(PATH)
    @player.pause
    @player.seek(50, :percent)
    @player.position.should be_within(1).of(125)
  end

  it "has a default speed of 1" do
    @player.speed.should eq(1.0)
  end

  it "speeds up playback" do
    @player.speed = 2.0
    @player.play(PATH)
    @player.should be_playing
    sleep 0.15
    @player.should_not be_playing
  end

  it "slows down playback" do
    @player.speed = 0.5
    @player.play(PATH)
    @player.should be_playing
    sleep 0.3
    @player.should be_playing
    sleep 0.3
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
    @player.play(PATH)
    @player.position.should be_within(5).of(5)
    sleep 0.1
    @player.position.should be_within(10).of(105)
  end

  it "tells you the length of the track in milliseconds" do
    @player.play(PATH)
    @player.track_length.should eq(250)
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
    @player.play(PATH)
    @player.pause.should be_true
    @player.pause.should eq(false)
    @player.resume.should be_true
    @player.resume.should eq(false)
  end
end

