# encoding: utf-8
require_relative "s3helper"
require 'open-uri'
require 'tempfile'
require 'faker'

include S3helper

# Heads-up: need to set environment variables before running these tests.  See s3helper.rb for details.

describe S3helper do

  it "references a valid bucket" do
    expect(Filestore::bucket.exists?).to be true
  end

  it "returns a valid URI base" do
    expect(Filestore::uribase).to match(/^https?:\/\/[a-z0-9]([-a-z0-9]*[a-z0-9])?(\.[a-z0-9]([-a-z0-9]*[a-z0-9])?)*\/$/)
  end

  context "for a simple file" do
    before :all do
      @file = Tempfile.new('foo')
      @message = Faker::Lorem::paragraph
      @file.write(@message)
      @file.close
      @path = "rspec-testfile"
    end

    after :all do
      @file.unlink
    end

    it "should be able to save the file" do
      expect(Filestore::write(@path, @file)).to be_an(AWS::S3::S3Object)
    end

    it "should be able to check that the saved file is there" do
      expect(Filestore::exists?(@path)).to be true
    end

    it "should be able to see the saved file in the directory listing" do
      expect(Filestore::ls).to include(@path)
    end

    it "should be able to pattern-match the filename with ?" do
      match = @path.clone
      match[rand(match.length)] = '?'
      match[rand(match.length)] = '?'
      expect(Filestore::ls(nil,match)).to include(@path)
    end

    it "should not match a non-matching pattern with ?" do
      expect(Filestore::ls(nil,@path+'?')).to_not include(@path)
    end

    it "should be able to pattern-match the filename with *" do
      match = @path.clone
      match[rand(match.length)..-1] = '*'
      expect(Filestore::ls(nil,match)).to include(@path)
    end

    it "should not match a non-matching pattern with *" do
      expect(Filestore::ls(nil,@path+'z*')).to_not include(@path)
    end

    it "should be able to read the file" do
      text = Filestore::read(@path)
      expect(text).to eq(@message)
    end

    it "should be able to read the file via http" do
      text = open(Filestore::uribase + @path).read
      expect(text).to eq(@message)
    end

    it "should be able to delete the file" do
      Filestore::delete(@path)
      expect(Filestore::exists?(@path)).to be false
    end

    it "should no longer be able to see the saved file in the directory listing" do
      expect(Filestore::ls).to_not include(@testfile)
    end

  end

  context "for a file in a directory" do
    before :all do
      @file = Tempfile.new('foo')
      @message = Faker::Lorem::paragraph
      @file.write(@message)
      @file.close
      @dir = "rspec-tmp/"
      @testfile = "happyfile"
      @path = @dir + @testfile
    end

    after :all do
      @file.unlink
    end

    it "should be able to save the file" do
      expect(Filestore::write(@path, @file)).to be_an(AWS::S3::S3Object)
    end

    it "should be able to check that the saved file is there" do
      expect(Filestore::exists?(@path)).to be true
    end

    it "should be able to see the directory" do
      expect(Filestore::lsdir).to include(@dir)
    end

    it "should be able to see the saved file in the directory listing" do
      expect(Filestore::ls(@dir)).to include(@testfile)
    end

    it "should allow the trailing slash to be omitted from the directory" do
      dir = @dir.sub(/\/$/,'')
      expect(Filestore::ls(dir)).to include(@testfile)
    end

    it "should be able to pattern-match the filename with ?" do
      match = @testfile.clone
      match[rand(match.length)] = '?'
      match[rand(match.length)] = '?'
      expect(Filestore::ls(@dir,match)).to include(@testfile)
    end

    it "should not match a non-matching pattern with ?" do
      expect(Filestore::ls(@dir,@testfile+'?')).to_not include(@testfile)
    end

    it "should be able to pattern-match the filename with *" do
      match = @testfile.clone
      match[rand(match.length)..-1] = '*'
      expect(Filestore::ls(@dir,match)).to include(@testfile)
    end

    it "should not match a non-matching pattern with *" do
      expect(Filestore::ls(@dir,@testfile+'z*')).to_not include(@testfile)
    end

    it "should be able to see the file's directory" do
      expect(Filestore::lsdir).to include(@dir)
    end

    it "should be able to read the file" do
      text = Filestore::read(@path)
      expect(text).to eq(@message)
    end

    it "should be able to read the file via http" do
      text = open(Filestore::uribase + @path).read
      expect(text).to eq(@message)
    end

    it "should be able to delete the file" do
      Filestore::delete(@path)
      expect(Filestore::exists?(@path)).to be false
    end

  end

  context "for a file in a directory in a directory" do
    before :all do
      @file = Tempfile.new('foo')
      @message = Faker::Lorem::paragraph
      @file.write(@message)
      @file.close
      @dir = "rspec-tmp/"
      @subdir = "subdir/"
      @testfile = "imfinethanks.txt"
      @path = @dir + @subdir + @testfile
    end

    after :all do
      @file.unlink
    end

    it "should be able to save the file" do
      expect(Filestore::write(@path, @file)).to be_an(AWS::S3::S3Object)
    end

    it "should be able to check that the saved file is there" do
      expect(Filestore::exists?(@path)).to be true
    end

    it "should be able to see the subdirectory in the directory listing" do
      expect(Filestore::lsdir(@dir)).to include(@subdir)
    end

    it "should be able to see the saved file in the subdirectory listing" do
      expect(Filestore::ls(@dir + @subdir)).to include(@testfile)
    end

    it "should be able to read the file" do
      text = Filestore::read(@path)
      expect(text).to eq(@message)
    end

    it "should be able to read the file via http" do
      text = open(Filestore::uribase + @path).read
      expect(text).to eq(@message)
    end

    it "should be able to delete the file" do
      Filestore::delete(@path)
      expect(Filestore::exists?(@path)).to be false
    end

  end

end
