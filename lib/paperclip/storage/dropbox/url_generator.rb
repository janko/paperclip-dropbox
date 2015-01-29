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
            url = file_url(style)
            url = URI.parse(url)
            url.query = [url.query, "dl=1"].compact.join("&") if options[:download]
            url.to_s
          else
            @attachment_options[:interpolator].interpolate(@attachment_options[:default_url], @attachment, style)
          end
        end

        private

        def user_id
          @attachment.dropbox_credentials[:user_id]
        end
      end

    end
  end
end
