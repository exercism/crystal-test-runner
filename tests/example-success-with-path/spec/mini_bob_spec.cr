require "spec"
require "../src/*"

describe Bob::Bob1 do
  it "responds to stating something" do
    Bob::Bob1.hey("Tom-ay-to, tom-aaaah-to.").should eq "Whatever."
  end
end
