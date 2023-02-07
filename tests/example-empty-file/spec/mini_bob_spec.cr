require "spec"
require "../src/*"

describe "Bob" do
  it "responds to stating something" do
    Bob.hey("Tom-ay-to, tom-aaaah-to.").should eq "Whatever."
  end
end
