require "spec_helper"

describe Plllayer::TimeHelpers do
  describe :format_time do
    it "formats a time of zero milliseconds" do
      Plllayer.format_time(0).should eq("0:00")
    end

    it "formats a time of one millisecond" do
      Plllayer.format_time(1).should eq("0:00.001")
    end

    it "formats a time of one second" do
      Plllayer.format_time(1000).should eq("0:01")
    end

    it "formats a time of one second plus a millisecond" do
      Plllayer.format_time(1001).should eq("0:01.001")
    end

    it "formats a time of one minute and thirty seconds" do
      Plllayer.format_time(90000).should eq("1:30")
    end

    it "formats times of an hour" do
      Plllayer.format_time(3600000).should eq("1:00:00")
    end

    it "formats times with multiple components" do
      Plllayer.format_time(7200000 + 120000 + 2000 + 2).should eq("2:02:02.002")
    end

    it "can exclude milliseconds from the output" do
      Plllayer.format_time(1500).should eq("0:01.500")
      Plllayer.format_time(1500, include_milliseconds: false).should eq("0:01")
    end

    it "can't format negative times" do
      expect { Plllayer.format_time(-1) }.to raise_error(ArgumentError)
    end
  end

  describe :parse_time do
    it "parses times of zero" do
      Plllayer.parse_time("0").should eq(0)
      Plllayer.parse_time("0:00").should eq(0)
      Plllayer.parse_time("0:00.000").should eq(0)
      Plllayer.parse_time("0:00:00.000").should eq(0)
    end

    it "parses milliseconds" do
      Plllayer.parse_time("0.001").should eq(1)
      Plllayer.parse_time("0:00.999").should eq(999)
      Plllayer.parse_time("0:00:00.5").should eq(500)
    end

    it "parses seconds" do
      Plllayer.parse_time("1").should eq(1000)
      Plllayer.parse_time("0:05").should eq(5000)
      Plllayer.parse_time("0:00:09.500").should eq(9500)
    end

    it "parses minutes" do
      Plllayer.parse_time("2:30").should eq(150000)
    end

    it "parses hours" do
      Plllayer.parse_time("1:00:00").should eq(3600000)
      Plllayer.parse_time("2:02:02.002").should eq(7200000 + 120000 + 2000 + 2)
      Plllayer.parse_time("1000:00:00").should eq(1000 * 3600000)
    end

    it "assumes empty components are zero" do
      Plllayer.parse_time("1:").should eq(60000)
      Plllayer.parse_time("1::.5").should eq(3600000 + 500)
      Plllayer.parse_time("::.001").should eq(1)
      Plllayer.parse_time("::6.").should eq(6000)
      Plllayer.parse_time("").should eq(0)
    end

    it "can't parse invalid strings" do
      expect { Plllayer.parse_time("-1") }.to raise_error(ArgumentError)
      expect { Plllayer.parse_time("1:00:00:00") }.to raise_error(ArgumentError)
    end
  end
end

