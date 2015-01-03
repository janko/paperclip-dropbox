require "paperclip/storage/dropbox/private_url_generator"
require "paperclip/storage/dropbox/public_url_generator"
module Paperclip
  module Storage
    module Dropbox
      module GeneratorFactory
        def self.build_url_generator(storage, options)
          credentials = storage.try(:dropbox_credentials) || options[:dropbox_credentials]
          if credentials[:access_type] == "app_folder" || options[:dropbox_visibility] == "private"
            PrivateUrlGenerator.new(storage, options)
          elsif credentials[:access_type]
            PublicUrlGenerator.new(storage, options)
          end
        end
      end
    end
  end
end

