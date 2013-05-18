require "paperclip"
require_relative "credentials"

Paperclip.options[:log] = false
Paperclip::Attachment.default_options.merge!(
  storage: :dropbox, dropbox_credentials: CREDENTIALS[:dropbox]
)
