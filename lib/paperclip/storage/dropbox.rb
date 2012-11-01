require 'dropbox_sdk'
require 'active_support/core_ext/hash/keys'
require 'active_support/inflector/methods'
require 'yaml'
require 'erb'

module Paperclip
  module Storage
    module Dropbox
      def self.extended(base)
        base.instance_eval do
          @dropbox_credentials = parse_credentials(@options[:dropbox_credentials] || {})
          @dropbox_options = @options[:dropbox_options] || {}
          environment = defined?(Rails) ? Rails.env : @dropbox_options[:environment].to_s
          @dropbox_credentials = (@dropbox_credentials[environment] || @dropbox_credentials).symbolize_keys
          dropbox_client # Force validations of credentials
        end
      end

      def flush_writes
        @queued_for_write.each do |style, file|
          unless exists?(style)
            dropbox_client.put_file(path(style), file.read)
          else
            raise FileExists, "file \"#{path(style)}\" already exists on Dropbox"
          end
        end
        after_flush_writes
        @queued_for_write = {}
      end

      def flush_deletes
        @queued_for_delete.each do |path|
          dropbox_client.file_delete(path)
        end
        @queued_for_delete = []
      end

      def exists?(style)
        !!dropbox_client.media(path(style))
      rescue DropboxError
        false
      end

      def url(*args)
        if present?
          style = args.first.is_a?(Symbol) ? args.first : default_style
          options = args.last.is_a?(Hash) ? args.last : {}
          query = options[:download] ? "?dl=1" : ""

          File.join("http://dl.dropbox.com/u/#{user_id}", path_for_url(style) + query)
        end
      end

      def path(style)
        File.join("Public", path_for_url(style))
      end

      def path_for_url(style)
        result = instance.instance_exec(style, &file_path)
        result += extension if result !~ /\.\w{3,4}$/
        style_suffix = (style != default_style ? "_#{style}" : "")
        result.sub(extension, "#{style_suffix}#{extension}")
      end

      def copy_to_local_file(style, destination_path)
        local_file = File.open(destination_path, "wb")
        local_file.write(dropbox_client.get_file(path(style)))
        local_file.close
      end

      private

      def extension
        original_filename[/\.\w{3,4}$/]
      end

      def user_id
        @dropbox_credentials[:user_id]
      end

      def file_path
        return @dropbox_options[:path] if @dropbox_options[:path]

        if @dropbox_options[:unique_filename]
          eval %(proc { |style| "\#{self.class.model_name.underscore}_\#{id}_\#{#{name}.name}" })
        else
          eval %(proc { |style| #{name}.original_filename })
        end
      end

      def dropbox_client
        @dropbox_client ||= begin
          assert_required_keys
          session = DropboxSession.new(@dropbox_credentials[:app_key], @dropbox_credentials[:app_secret])
          session.set_access_token(@dropbox_credentials[:access_token], @dropbox_credentials[:access_token_secret])
          DropboxClient.new(session, "dropbox")
        end
      end

      def assert_required_keys
        [:app_key, :app_secret, :access_token, :access_token_secret, :user_id].each do |key|
          @dropbox_credentials.fetch(key)
        end
      end

      def parse_credentials(credentials)
        result =
          case credentials
          when File
            YAML.load(ERB.new(File.read(credentials.path)).result)
          when String, Pathname
            YAML.load(ERB.new(File.read(credentials)).result)
          when Hash
            credentials
          else
            raise ArgumentError, ":dropbox_credentials are not a path, file, nor a hash"
          end

        result.stringify_keys
      end

      class FileExists < ArgumentError
      end
    end
  end
end
