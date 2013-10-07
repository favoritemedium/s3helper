s3helper
========

A few methods to simplify using Amazon S3 as a filestore.

## Dependencies

    $ gem install aws-sdk
    $ export S3_ACCESS_KEY_ID=" ... "
    $ export S3_SECRET_ACCESS_KEY=" ... "
    $ export S3_BUCKET=" ... "
    $ export S3_HOST=" ... "


For running the tests:

    $ gem install rspec
    $ gem install faker

## Usage

Include module **S3helper** for the following useful functions:

### Filestore::ls(dirpath = nil, filesmatch = '\*')

Get a directory listing. Returns an array of filenames.

- simple globbing (\* and ?) is supported on **filesmatch**
- **dirpath** must not have a leading slash
- **filesmatch** must not contain any slashes
- only lists simple files; to list subdirectories use **lsdir**

### Filestore::lsdir(dirpath = nil)

Returns an array of names of subdirectories.

### Filestore::write(path, file)

Save file **file**.

- silently overwrites any existing file
- **path** is the full path without a leading slash

### Filestore::read(path)

Read file into memory. Returns a string.

### Filestore::exists?(path)

Returns true or false.

### Filestore::delete(path)

Remove the specified file.

### Filestore::uribase

Returns a string such that `Filestore::uribase + path` gives the full URI to access the resource (e.g. for use in an &lt;img&gt; tag).
