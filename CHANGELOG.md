# Changelog

## Version 1.1.1

- The `:default_url` option is now used when the attachment is blank.

## Version 1.1.0

New stuff:

- Added support for apps with the "App folder" access type (previously
  only "Full Dropbox" apps were supported).

Bug fixes:

- Fixed a bug where an error was raised when calling `#url` on a blank
  attachment.

- The Rake task is now properly loaded in non-Rails applications.
