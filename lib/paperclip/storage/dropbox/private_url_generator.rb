require "paperclip/storage/dropbox/url_generator"
module Paperclip
  module Storage
    module Dropbox
      class PrivateUrlGenerator < UrlGenerator
        def file_url(style)
          @attachment.dropbox_client.media(@attachment.path(style))["url"]
        end
      end
    end
  end
end

