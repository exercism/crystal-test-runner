require "spec"
require "../src/*"

describe "WarmUp" do
  it "counts words" do
    WarmUp.hey("Hello hello world").should eq "hello, hello, world 3"
  end

  it "splits digits" do
    WarmUp.digits(1234).should eq [1, 2, 3, 4]
  end

  it "raises" do
    expect_raises(ArgumentError) { WarmUp.average([] of Float64) }
    WarmUp.average([1.0, 2.0]).should be_close(1.5, 0.01)
  end
end
