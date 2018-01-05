require "paperclip/storage/dropbox/url_generator"
module Paperclip
  module Storage
    module Dropbox
      class PrivateUrlGenerator < UrlGenerator
        def file_url(style)
          @attachment.dropbox_client.get_temporary_link(@attachment.path(style))["link"]
        end
      end
    end
  end
end

