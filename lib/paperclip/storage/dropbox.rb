require 'dropbox_sdk'
require 'active_support/core_ext/hash/keys'
require "yaml"
require "erb"

module Paperclip
  module Storage
    module Dropbox
      def self.extended(base)
        base.instance_eval do
          @options[:dropbox_credentials] = parse_credentials(@options[:dropbox_credentials])
        end
      end

      def dropbox_session
        @dropbox_session ||= begin
          app_key, app_secret = @options[:dropbox_credentials].slice(:app_key, :app_secret).values
          access_token = @options[:dropbox_credentials].slice(:access_token, :access_token_secret).values

          DropboxSession.new(app_key, app_secret).tap do |session|
            session.set_access_token(*access_token)
          end
        end
      end

      def dropbox_client
        access_type = @options[:dropbox_credentials][:access_type] || :app_folder
        @dropbox_client ||= DropboxClient.new(dropbox_session, access_type)
      end

      def flush_writes
        @queued_for_write.each do |style, file|
          filename = filename_for(file.original_filename, style)
          dropbox_client.put_file(filename, file.read)
        end
        @queued_for_write = {}
      end

      def flush_deletes
        @queued_for_delete.each do |filename|
          dropbox_client.file_delete(filename)
        end
        @queued_for_delete = []
      end

      def exists?(style)
        dropbox_client.search("", path(style)).any?
      end

      def url(style, options = {})
        query = options[:download] ? "?dl=1" : ""
        dropbox_client.media(path(style))["url"] + query
      end

      def path(style)
        filename_for(original_filename, style)
      end

      private

      def filename_for(filename, style)
        if style != :original
          filename.sub(/(?=\.\w{3,4}$)/, "_#{style}")
        else
          filename
        end
      end

      def parse_credentials(credentials)
        credentials = credentials.respond_to?(:call) ? credentials.call : credentials
        credentials = get_credentials(credentials).stringify_keys
        environment = Object.const_defined?(:Rails) ? Rails.env : @options[:environment].to_s
        (credentials[environment] || credentials).symbolize_keys
      end

      def get_credentials(credentials)
        case credentials
        when File
          YAML.load(ERB.new(File.read(credentials.path)).result)
        when String, Pathname
          YAML.load(ERB.new(File.read(credentials)).result)
        when Hash
          credentials
        else
          raise ArgumentError, "Credentials are not a path, file, or hash."
        end
      end
    end
  end
end
