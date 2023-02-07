require "spec"
require "../src/*"

describe "Bob" do
  it "responds to stating something" do
    Bob.hey("Tom-ay-to, tom-aaaah-to.").should eq "Whatever."
  end

  it "responds to blank input" do
    Bob.hey("       ").should eq "Fine. Be that way!"
  end
end
