require 'dropbox_sdk'
require 'active_support/core_ext/hash/keys'
require 'active_support/inflector/methods'
require 'yaml'
require 'erb'

module Paperclip
  module Storage
    module Dropbox
      attr_reader :dropbox_client

      def self.extended(base)
        base.instance_eval do
          @dropbox_settings = parse_settings(@options[:dropbox_settings] || {})
          @dropbox_settings.update(@options[:dropbox_options] || {})

          session = DropboxSession.new(@dropbox_settings[:app_key], @dropbox_settings[:app_secret])
          session.set_access_token(@dropbox_settings[:access_token], @dropbox_settings[:access_token_secret])

          @dropbox_client = DropboxClient.new(session, @dropbox_settings[:access_type] || :app_folder)

          @dropbox_keywords = Hash.new do |hash, key|
            if key =~ /^\<record_.+\>$/
              attribute = key.match(/^\<record_(.+)\>$/)[1]
              hash[key] = lambda { |style| instance.send(attribute) }
            end
          end
          @dropbox_keywords.update(
            "<model_name>"      => lambda { |style| instance.class.table_name.singularize },
            "<table_name>"      => lambda { |style| instance.class.table_name },
            "<filename>"        => lambda { |style| original_filename.match(/\.\w{3,4}$/).pre_match },
            "<attachment_name>" => lambda { |style| name },
            "<style>"           => lambda { |style| style }
          )
        end
      end

      def flush_writes
        @queued_for_write.each do |style, file|
          unless exists?(style)
            response = dropbox_client.put_file(path(style), file.read)
          else
            raise FileExists, "\"#{path(style)}\" already exists on Dropbox"
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
        !!url(style)
      end

      def url(*args)
        style = args.first.is_a?(Symbol) ? args.first : default_style
        options = args.last.is_a?(Hash) ? args.last : {}
        query = options[:download] ? "?dl=1" : ""

        dropbox_client.media(path(style).to_s)["url"] + query

      rescue DropboxError
        nil
      end

      def path(style)
        extension = original_filename[/\.\w{3,4}$/]
        result = file_path
        file_path.scan(/\<\w+\>/).each do |keyword|
          result.sub!(keyword, @dropbox_keywords[keyword].call(style).to_s)
        end
        style_suffix = style != default_style ? "_#{style}" : ""
        result = "#{result}#{style_suffix}#{extension}"

      rescue
        nil
      end

      def copy_to_local_file(style, destination_path)
        local_file = File.open(destination_path, "wb")
        local_file.write(dropbox_client.get_file(path(style)))
        local_file.close
      end

      private

      def file_path
        return @dropbox_settings[:path] if @dropbox_settings[:path]

        if @dropbox_settings[:unique_filename]
          "<model_name>_<record_id>_<attachment_name>"
        else
          "<filename>"
        end
      end

      def parse_settings(settings)
        settings = settings.respond_to?(:call) ? settings.call : settings
        settings = get_settings(settings).stringify_keys
        environment = defined?(Rails) ? Rails.env : @dropbox_settings[:environment].to_s
        (settings[environment] || settings).symbolize_keys
      end

      def get_settings(settings)
        case settings
        when File
          YAML.load(ERB.new(File.read(settings.path)).result)
        when String, Pathname
          YAML.load(ERB.new(File.read(settings)).result)
        when Hash
          settings
        else
          raise ArgumentError, "settings are not a path, file, or hash."
        end
      end

      class FileExists < RuntimeError
      end
    end
  end
end
