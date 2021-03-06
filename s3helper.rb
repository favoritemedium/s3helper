# encoding: utf-8
require 'aws-sdk'

# depends on the following environment variables:
#
# S3_ACCESS_KEY_ID (20 characters, alphanumeric)
# S3_SECRET_ACCESS_KEY (40 characters, top secret)
# S3_BUCKET (e.g. "my-amazon-files")
# S3_HOST (e.g. "s3-ap-southeast-1.amazonaws.com")

module S3helper
  class Filestore
    class << self

      @@mutex = Mutex.new

      # get the bucket instance (probably never need to use this directly)
      def bucket
        @bucket = AWS::S3.new(:access_key_id => ENV["S3_ACCESS_KEY_ID"], :secret_access_key => ENV["S3_SECRET_ACCESS_KEY"]).buckets[ENV["S3_BUCKET"]] if @bucket.nil?
        @bucket
      end

      # list all simple files in a directory (subdirectories are ignored)
      # dirpath must not have a leading slash
      # file matching supports basic globbing (* and ?)
      def ls(dirpath = nil, filesmatch = '*')
        dirpath << '/' unless dirpath.nil? || dirpath.end_with?('/')
        offset = dirpath.nil? ? 0 : dirpath.length
        r = Regexp.new("^#{Regexp.escape(filesmatch)}$".gsub('\*','.*').gsub('\?','.'))
        bucket.as_tree(:prefix => dirpath).children.select(&:leaf?).map{|f| f.key[offset..-1]}.select{|f| f.match(r)}
      end

      # list all (sub)directories
      # dirpath must not have a leading slash
      def lsdir(dirpath = nil)
        dirpath << '/' unless dirpath.nil? || dirpath.end_with?('/')
        offset = dirpath.nil? ? 0 : dirpath.length
        bucket.as_tree(:prefix => dirpath).children.select(&:branch?).map{|f| f.prefix[offset..-1]}
      end

      # write a file to S3
      # path is the aws key (= full path), no leading slash
      def write(path, file)
        bucket.objects[path].write(:file => file, :acl => :public_read)
      end

      # write a file to S3 without overwriting anything
      # adds an iteration number to the path as needed and returns the path actually used
      def writenc(path, file)
        bucket
        @@mutex.synchronize do
          path = find_available_name(path)
          bucket.objects[path].write(:file => file, :acl => :public_read)
        end
        path
      end

      # read a file
      def read(path)
        bucket.objects[path].read
      end

      # check for file
      def exists?(path)
        bucket.objects[path].exists?
      end

      # rename a file
      def rename(oldpath, newpath)
        bucket.objects[oldpath].move_to(newpath, :acl => :public_read)
      end

      # rename a file without overwriting anything
      # adds an iteration number to the path as needed and returns the path actually used
      def renamenc(oldpath, newpath)
        bucket
        @@mutex.synchronize do
          newpath = find_available_name(newpath)
          bucket.objects[oldpath].move_to(newpath, :acl => :public_read)
        end
        newpath
      end

      # remove a file from S3
      def delete(path)
        bucket.objects.delete(path)
      end

      # public access url; append the path to this
      def uribase
        "http://#{ENV['S3_BUCKET']}.#{ENV["S3_HOST"]}/"
      end

      # helper method for writenc and renamemc
      # find an unused pathname by appending "-1", "-2", etc.
      def find_available_name(path)
        return path unless bucket.objects[path].exists?
        ext = File.extname(path)
        base = path[0..-ext.size-1] + "-1"
        loop do
          path = base + ext
          return path unless bucket.objects[path].exists?
          base = base.next
        end
      end

    end
  end # class Filestore
end # module S3helper
