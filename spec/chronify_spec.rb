require File.dirname(__FILE__) + '/spec_helper'

require "open3"
require "yaml"

describe "chronify" do
  before(:all) do
    @chronify = File.dirname(__FILE__) + "/../mod/chronify.rb"
  end

  it "should handle YYYY, Mon" do
    cmd = "#{@chronify} --column 0:YYYY --column 1:Month"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2005\tAug\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "24067\t42\n"
      log[:columns].first[:chron].should == 'YYYYMM'
    end
  end

  it "should handle YYYY, Q" do
    cmd = "#{@chronify} --column 0:YYYY --column 1:Quarter"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2004\t3\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "8018\t42\n"
      log[:columns].first[:chron].should == 'YYYYQ'
    end
  end

  it "should handle YYYY, QtrQ" do
    cmd = "#{@chronify} --column 0:YYYY --column 1:Quarter"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2004\tQtr2\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "8017\t42\n"
      log[:columns].first[:chron].should == 'YYYYQ'
    end
  end

  it "should handle YYYYQ" do
    cmd = "#{@chronify} --column 0:YYYYQ"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << "2004Q2\t42\n"
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.should == "8017\t42\n"
      log[:columns].first[:chron].should == 'YYYYQ'
    end
  end

  it "should reject bad rows" do
    cmd = "#{@chronify} --column 0:YYYY --column 1:Month"
    Open3.popen3(cmd) do |stdin, stdout, stderr|
      stdin << testdata('monthlydata.tsv')
      stdin.close
      result = stdout.read
      log = YAML.load(stderr.read)

      result.split(/\n/).size.should == 5
      result.split(/\n/).size.should == log[:nrows]
      log[:rejected_rows].should == 1
      log[:columns].size.should == 1
      log[:chron_rows].size.should == 1
    end
  end
end
