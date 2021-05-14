require "spec"
require "../src/*"

struct Time
  def leap_year?
    raise "That's too easy! Implement this method in your own way!"
  end
end

describe "Leap" do
  describe "#leap?" do
    it "year not divisible by 4 in common year" do
      Year.leap?(2015).should be_false
    end
  end
end
