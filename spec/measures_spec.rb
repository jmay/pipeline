require File.dirname(__FILE__) + '/spec_helper'

require "open3"
require "yaml"

require "dataset"

describe "measures" do
  before(:all) do
    @measures = File.dirname(__FILE__) + "/../mod/measures.rb"
  end

  it "should filter out non-numeric values" do
    cmd = "#{@measures} --column 1,2 --format Discrete"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2005\t---\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "2005\t\t42\n"
      log[:columns][2][:units].should == Dataset::Units::Discrete
    end
  end
end
