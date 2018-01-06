require "paperclip/storage/dropbox/url_generator"
module Paperclip
  module Storage
    module Dropbox
      class PrivateUrlGenerator < UrlGenerator
        def file_url(style)
          result = @attachment.dropbox_client.get_temporary_link(@attachment.path(style))
          result.link
        end
      end
    end
  end
end

