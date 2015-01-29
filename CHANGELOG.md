# Changelog

## Version 1.3.1

* Fix dropbox credentials not working when set with Pathname or String

## Version 1.3.0

- `:dropbox_credentials` can now be a Proc (credits to @dukz)

## Version 1.2.2

- Fixed `undefined method \`genreate' for nil:NilClass` when the `:access_type`
  option is not set.

## Version 1.2.1

- Allow Paperclip 4 to be used with this gem.

## Version 1.2.0

- Add ability to provide any directory in **Full Dropbox** mode (Thanks,
  @dougbradbury).

## Version 1.1.7

- Fix gem not defaulting to "full dropbox" access type.

## Version 1.1.6 (yanked)

- `#exists?` now returns `false` when the attachment is not present

## Version 1.1.5

- `:default_url` is now interpolated.

## Version 1.1.4

- Enable usage of Paperclip's `:path` option.

## Version 1.1.3

- In Attachment#exists? made the `style` argument optional.

## Version 1.1.2

- An error is now raised when any of the credentials are `nil`.

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
