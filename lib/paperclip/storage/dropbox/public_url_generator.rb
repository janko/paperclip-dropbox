require "paperclip/storage/dropbox/url_generator"
module Paperclip
  module Storage
    module Dropbox
      class PublicUrlGenerator < UrlGenerator
        def file_url(style)
          url = URI.parse("https://dl.dropboxusercontent.com/u/#{user_id}/")
          path = @attachment.path(style)
          path = path.match(/^Public\//).try(:post_match)
          url.merge!(path)
          url.to_s
        end
      end
    end
  end
end
