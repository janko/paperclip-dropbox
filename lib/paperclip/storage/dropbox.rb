require 'dropbox_sdk'
require 'active_support/core_ext/hash/keys'
require "yaml"
require "erb"

module Paperclip
  module Storage
    module Dropbox
      class FileExists < RuntimeError
      end

      DEFAULTS = {
        unique_identifier: :id,
        unique_filename: false
      }

      def self.extended(base)
        base.instance_eval do
          @options[:dropbox_credentials] = parse_credentials(@options[:dropbox_credentials])
          @options[:dropbox_options] = DEFAULTS.merge(options[:dropbox_options] || {})
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
        @dropbox_client ||= begin
          access_type = @options[:dropbox_credentials][:access_type] || :app_folder
          DropboxClient.new(dropbox_session, access_type)
        end
      end

      def flush_writes
        @queued_for_write.each do |style, file|
          filename = filename_for(instance_read(:file_name), style)
          if unique_filename? or !exists?(style)
            response = dropbox_client.put_file(filename, file.read)
            instance_write(:file_name, File.basename(response["path"])) if style == default_style
          else
            raise FileExists, "\"#{filename}\" already exists on Dropbox"
          end
        end

        after_flush_writes
        @queued_for_write = {}
      end

      def flush_deletes
        @queued_for_delete.each do |filename|
          dropbox_client.file_delete(filename)
        end
        @queued_for_delete = []
      end

      def exists?(style)
        !!url(style)
      end

      def url(*args)
        style = args.first.is_a?(Symbol) ? args.first : default_style
        options = args.last.is_a?(Hash) ? args.last : {}
        query = options[:download] ? "?dl=1" : ""

        dropbox_client.media(path(style))["url"] + query

      rescue DropboxError
        nil
      end

      def path(style)
        filename_for(original_filename, style)
      end

      private

      def filename_for(filename, style = default_style)
        match = filename.match(/\.\w{3,4}$/)
        extension = match[0]
        before_extension =
          unless unique_filename?
            match.pre_match
          else
            "#{unique_identifier}_#{name}"
          end
        style_suffix = style != default_style ? "_#{style}" : ""

        result_filename = "#{before_extension}#{style_suffix}#{extension}"

        if @options[:dropbox_folder]
          File.join(@options[:dropbox_folder], result_filename)
        else
          result_filename
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

      def unique_filename?
        @options[:dropbox_options][:unique_filename]
      end

      def unique_identifier
        instance.send(@options[:dropbox_options][:unique_identifier])
      end
    end
  end
end
