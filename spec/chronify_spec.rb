require File.dirname(__FILE__) + '/spec_helper'

require "open3"
require "yaml"

describe "chronify" do
  before(:all) do
    @chronify = File.dirname(__FILE__) + "/../mod/chronify"
  end

  it "should handle YYYY, Mon" do
    cmd = "#{@chronify} --column 0:YYYY --column 1:Mon"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2005\tAug\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "24067\t42\n"
      log[:chron].should == 'YYYYMM'
    end
  end

  it "should handle YYYY, Q" do
    cmd = "#{@chronify} --column 0:YYYY --column 1:Q"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2004\t3\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "8018\t42\n"
      log[:chron].should == 'YYYYQ'
    end
  end

  it "should handle YYYY, QtrQ" do
    cmd = "#{@chronify} --column 0:YYYY --column 1:Q"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2004\tQtr2\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "8017\t42\n"
      log[:chron].should == 'YYYYQ'
    end
  end
end
