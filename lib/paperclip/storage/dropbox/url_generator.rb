require "uri"

module Paperclip
  module Storage
    module Dropbox
      class UrlGenerator
        def initialize(attachment, attachment_options)
          @attachment = attachment
          @attachment_options = attachment_options
        end

        def generate(style, options)
          if @attachment.present?
            url = @attachment.full_dropbox? ? public_url(style) : private_url(style)
            url = URI.parse(url)
            url.query = [url.query, "dl=1"].compact.join("&") if options[:download]
            url.to_s
          else
            @attachment_options[:interpolator].interpolate(@attachment_options[:default_url], @attachment, style)
          end
        end

        private

        def private_url(style)
          @attachment.dropbox_client.media(@attachment.path(style))["url"]
        end

        def public_url(style)
          url = URI.parse("https://dl.dropboxusercontent.com/u/#{user_id}/")
          path = @attachment.path(style)
          path = path.match(/^Public\//).post_match
          url.merge!(path)
          url.to_s
        end

        def user_id
          @attachment_options[:dropbox_credentials][:user_id]
        end
      end
    end
  end
end
