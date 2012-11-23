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
        metadata = dropbox_metadata(style)
        !metadata.nil? && !metadata['is_deleted']
      rescue DropboxError
        false
      end

      def url(*args)
        if present?
          style = args.first.is_a?(Symbol) ? args.first : default_style
          options = args.last.is_a?(Hash) ? args.last : {}
          query = options[:download] ? "?dl=1" : ""

          if app_folder_mode
            dropbox_client.media(path(style))['url'] + query
          else
            File.join("http://dl.dropbox.com/u/#{user_id}", path_for_url(style) + query)
          end
        end
      end

      def path(style)
        if app_folder_mode
          path_for_url(style)
        else
          File.join("Public", path_for_url(style))
        end
      end

      def path_for_url(style)
        path = instance.instance_exec(style, &file_path)
        style_suffix = (style != default_style ? "_#{style}" : "")

        if original_extension && path =~ /#{original_extension}$/
          path.sub(original_extension, "#{style_suffix}#{original_extension}")
        else
          path + style_suffix + original_extension.to_s
        end
      end

      def dropbox_metadata(style = default_style)
        dropbox_client.metadata(path(style))
      end

      def copy_to_local_file(style, destination_path)
        local_file = File.open(destination_path, "wb")
        local_file.write(dropbox_client.get_file(path(style)))
        local_file.close
      end

      private

      def original_extension
        original_filename[/\.[^.]+$/]
      end

      def user_id
        @dropbox_credentials[:user_id]
      end

      def app_folder_mode
        @dropbox_credentials[:access_level] == 'app_folder'
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
          DropboxClient.new(session, @dropbox_credentials[:access_level] || 'dropbox')
        end
      end

      def assert_required_keys
        [:app_key, :app_secret, :access_token, :access_token_secret, :user_id].each do |key|
          @dropbox_credentials.fetch(key)
        end
        if @dropbox_credentials[:access_level]
          if not ['dropbox', 'app_folder'].include?(@dropbox_credentials[:access_level])
            raise KeyError, ":access_level must be 'dropbox' or 'app_folder'"
          end
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
