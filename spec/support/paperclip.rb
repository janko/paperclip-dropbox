require "paperclip"
require_relative "credentials"

Paperclip.options[:log] = false
Paperclip::Attachment.default_options.merge!(
  storage: :dropbox, dropbox_credentials: CREDENTIALS[:dropbox],
  processors: [:noop]
)

module Paperclip
  class Noop < Processor
    def make
      file
    end
  end
end

Paperclip.configure do |config|
  config.register_processor :noop, Paperclip::Noop
end
