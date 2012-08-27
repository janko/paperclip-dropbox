module Paperclip
  module Storage
    module Dropbox
      def self.extended(base)
        require 'dropbox_sdk'
      end

      def dropbox_options
        @options["dropbox_options"]
      end

      def dropbox_credentials
        dropbox_options["credentials"]
      end

      def dropbox_session
        @dropbox_session ||= DropboxSession.new(dropbox_credentials["app_key"], dropbox_credentials["app_secret"]).tap do |session|
          session.set_access_token(dropbox_credentials["access_token"], dropbox_credentials["access_token_secret"])
        end
      end

      def dropbox_client
        @dropbox_client ||= DropboxClient.new(session, dropbox_options["access_type"])
      end

      def flush_writes
        @queued_for_write.each do |style, file|
          filename = "#{file.original_filename}_#{style}"
          if dropbox_client.media(filename)
            dropbox_client.file_delete(filename)
          end

          dropbox_client.put_file(filename, file.read)
        end

        after_flush_writes

        @queued_for_write = {}
      end

      def flush_deletes
        @queued_for_delete.each do |filename|
          begin
            dropbox_client.file_delete(filename)
          rescue DropboxError
          end
        end

        @queued_for_delete = []
      end
    end
  end
end
