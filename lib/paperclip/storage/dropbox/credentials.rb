require "yaml"
require "erb"
require "pathname"
require "active_support/core_ext/hash/keys"

module Paperclip
  module Storage
    module Dropbox
      class Credentials
        def initialize(credentials)
          @credentials = credentials
        end

        def fetch(namespace = nil)
          parse!(namespace)
          validate!
          @credentials
        end

        def parse!(namespace = nil)
          @credentials =
            case @credentials
            when File
              YAML.load(ERB.new(File.read(@credentials.path)).result)
            when String, Pathname
              YAML.load(ERB.new(File.read(@credentials)).result)
            when Hash
              @credentials
            else
              raise ArgumentError, ":dropbox_credentials is not a path, file, nor a hash"
            end

          @credentials.stringify_keys!
          @credentials = @credentials[namespace.to_s] || @credentials
          @credentials.symbolize_keys!

          @credentials
        end

        def validate!
          validate_presence!
          validate_inclusion!
        end

        private

        def validate_presence!
          REQUIRED_KEYS.each do |key|
            value = @credentials.fetch(key)
            raise KeyError, ":#{key} credential is nil" if value.nil?
          end
        end

        def validate_inclusion!
          if @credentials[:access_type] and not %w[dropbox app_folder].include?(@credentials[:access_type])
            raise KeyError, %(:access_type must be either "dropbox" or "app_folder" (was "#{@credentials[:access_type]}"))
          end
        end

        REQUIRED_KEYS = [
          :app_key, :app_secret,
          :access_token, :access_token_secret,
          :user_id
        ]
      end
    end
  end
end
