require "spec"
require "../src/*"

describe "ParallelLetterFrequency" do
  it "no texts" do
    input = [] of String
    expected = {} of String => Int32
    ParallelLetterFrequency.calculate_frequencies(input).should eq(expected)
  end

  pending "one text with one letter" do
    input = ["a"]
    expected = {"a" => 1}
    ParallelLetterFrequency.calculate_frequencies(input).should eq(expected)
  end

  pending "one text with multiple letters" do
    input = ["bbcccd"]
    expected = {"b" => 2, "c" => 3, "d" => 1}
    ParallelLetterFrequency.calculate_frequencies(input).should eq(expected)
  end

  pending "two texts with one letter" do
    input = ["e", "f"]
    expected = {"e" => 1, "f" => 1}
    ParallelLetterFrequency.calculate_frequencies(input).should eq(expected)
  end

  pending "two texts with multiple letters" do
    input = ["ggh", "hhi"]
    expected = {"g" => 2, "h" => 3, "i" => 1}
    ParallelLetterFrequency.calculate_frequencies(input).should eq(expected)
  end

  pending "ignore letter casing" do
    input = ["m", "M"]
    expected = {"m" => 2}
    ParallelLetterFrequency.calculate_frequencies(input).should eq(expected)
  end
end
