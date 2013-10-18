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

      @filetoo = Tempfile.new('bar')
      @messagetoo = Faker::Lorem::paragraph
      @filetoo.write(@messagetoo)
      @filetoo.close

      @path = "rspec-testfile.txt"
      @path1 = "rspec-testfile-1.txt"
      @path2 = "rspec-testfile-2.txt"

      Filestore::delete(@path)
      Filestore::delete(@path1)
      Filestore::delete(@path2)
    end

    after :all do
      @file.unlink
      @filetoo.unlink
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

    it "should be able to find the next available name" do
      newpath = Filestore::find_available_name(@path)
      expect(newpath).to eq(@path1)
    end

    it "should be able to save without clobbering" do
      newpath = Filestore::writenc(@path, @filetoo)
      expect(Filestore::exists?(newpath)).to be true
      expect(newpath).to eq(@path1)
      expect(Filestore::read(@path)).to eq(@message)
      expect(Filestore::read(newpath)).to eq(@messagetoo)
    end

    it "should be able to rename" do
      Filestore::rename(@path1,"voodoo")
      expect(Filestore::exists?("voodoo")).to be true
      expect(Filestore::exists?(@path1)).to be false
      Filestore::rename("voodoo",@path1)
    end

    it "should be able to rename without clobbering" do
      newpath = Filestore::renamenc(@path1,@path)
      expect(newpath).to eq(@path2)
      expect(Filestore::exists?("voodoo")).to be false
      expect(Filestore::exists?(@path2)).to be true
    end

    it "should be able to delete the file" do
      Filestore::delete(@path)
      expect(Filestore::exists?(@path)).to be false
    end

    it "should no longer be able to see the saved file in the directory listing" do
      expect(Filestore::ls).to_not include(@path)
      expect(Filestore::ls).to include(@path2)
    end

    it "should be able to delete the other file too" do
      Filestore::delete(@path2)
      expect(Filestore::exists?(@path2)).to be false
      expect(Filestore::ls).to_not include(@path2)
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
      @path1 = @path + "-1"
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

    it "should be able to find the next available name" do
      newpath = Filestore::find_available_name(@path)
      expect(newpath).to eq(@path1)
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
