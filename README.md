# SmugSync
The hacker-friendly command-line tool to synchronize your photos and videos two-way between your computer and SmugMug.

Warning: this tool is not yet ready for usage unless you're willing to read the code and learn its restrictions and quirks yourself.


## How it works
SmugSync provides a command-line interface that is somewhat similar to git or svn (but without versioning of course).

To start, initialize a root directory for your SmugMug account:

    smug init

Albums are stored as subdirs inside the root directory. To upload an album, create a directory for it, copy your images and videos there and run

    smug upload

To download existing albums from SmugMug use

    smug download       # not implemented yet!

To see the difference between your directory and SmugMug run

    smug status


## How is this tool different?
- it is written in Ruby and aimed at command line users
- its command line interface will be immediatelly familiar to git/svn users
- it uses OAuth and SmugMug 1.3.0 API
- it does two-way sync


## Restrictions
- Categories and subcategories are not supported.
