require "spec_helper"

TRACK_1 = "spec/250ms.mp3"
TRACK_2 = "spec/3000ms.mp3"
TRACK_3 = "spec/10000ms.mp3"

describe Plllayer do
  before(:each) do
    @player = Plllayer.new(external_player: :nop)
  end

  after(:each) do
    @player.stop
  end

  describe "playlist control" do
    it "appends tracks to the end of the playlist" do
      @player.append(TRACK_1, TRACK_2)
      @player << [TRACK_2, TRACK_3]
      @player.playlist.should eq([TRACK_1, TRACK_2, TRACK_2, TRACK_3])
    end

    it "inserts tracks anywhere in the playlist" do
      @player.insert_at(0, TRACK_1)
      @player.playlist.should eq([TRACK_1])
      @player.insert_at(0, TRACK_2)
      @player.playlist.should eq([TRACK_2, TRACK_1])
      @player.insert_at(1, TRACK_3)
      @player.playlist.should eq([TRACK_2, TRACK_3, TRACK_1])
      @player.insert_at(3, TRACK_1, TRACK_2, TRACK_3)
      @player.playlist.should eq([TRACK_2, TRACK_3, TRACK_1, TRACK_1, TRACK_2, TRACK_3])
    end

    it "inserts tracks after the currently playing track" do
      @player.insert(TRACK_1)
      @player.playlist.should eq([TRACK_1])
      @player.insert(TRACK_2)
      @player.playlist.should eq([TRACK_2, TRACK_1])
      @player.play
      @player.insert(TRACK_3)
      @player.playlist.should eq([TRACK_2, TRACK_3, TRACK_1])
    end

    it "removes tracks by object comparison" do
      @player << [TRACK_1, TRACK_2, TRACK_1, TRACK_3, TRACK_1]
      @player.remove(TRACK_1)
      @player.playlist.should eq([TRACK_2, TRACK_3])
      @player << [TRACK_1, TRACK_1, TRACK_1]
      @player.remove(TRACK_1, 2)
      @player.playlist.should eq([TRACK_2, TRACK_3, TRACK_1])
      @player.remove(TRACK_1, TRACK_2, TRACK_3)
      @player.playlist.should be_empty
    end

    it "removes one or more tracks anywhere in the playlist" do
      @player << [TRACK_1, TRACK_2, TRACK_3]
      @player.remove_at(1)
      @player.playlist.should eq([TRACK_1, TRACK_3])
      @player.remove_at(0, 2)
      @player.playlist.should be_empty
    end

    it "continues playing while playlist is modified" do
      @player << [TRACK_3, TRACK_2, TRACK_1]
      @player.play
      @player << TRACK_1
      @player.playlist.should eq([TRACK_3, TRACK_2, TRACK_1, TRACK_1])
      @player.track.should eq(TRACK_3)
      @player.remove(TRACK_3)
      @player.playlist.should eq([TRACK_2, TRACK_1, TRACK_1])
      @player.track.should eq(TRACK_2)
      @player.remove(TRACK_2, TRACK_1)
      @player.should_not be_playing
    end

    it "raises index error when inserting or removing out of the playlist's bounds" do
      expect { @player.insert_at(-3, TRACK_1) }.to raise_error(IndexError)
      expect { @player.insert_at(2, TRACK_1) }.to raise_error(IndexError)
      expect { @player.remove_at(-3) }.to raise_error(IndexError)
      expect { @player.remove_at(0) }.to raise_error(IndexError)
    end
  end
end

