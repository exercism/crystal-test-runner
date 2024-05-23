require "spec"
require "../src/*"

describe "Bob" do
  describe "hey", tags: "1" do
    it "responds to stating something" do
      Bob.hey("Tom-ay-to, tom-aaaah-to.").should eq "Whatever. Tom-ay-to, tom-aaaah-to."
    end

    it "doesnt add extra part when not given" do
      Bob.hey("").should eq "Whatever. "
    end
  end

  describe "bye", tags: "2" do
    it "says bye when calling bye" do
      Bob.bye("").should eq "Bye."
    end
  end
end
