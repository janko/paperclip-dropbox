# Changelog

## Version 1.1.6

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
