require "dropbox_sdk"

module Paperclip
  module Dropbox
    module Rake
      extend self

      def authorize(app_key, app_secret, access_type)
        session = create_new_session(app_key, app_secret)

        puts "Visit this URL: #{session.get_authorize_url}"
        print "And after you approved the authorization confirm it here (y/n): "

        assert_answer!
        session.get_access_token
        dropbox_client = DropboxClient.new(session, access_type)
        account_info = dropbox_client.account_info

        puts <<-MESSAGE

Authorization was successful. Here you go:

access_token: #{session.access_token.key}
access_token_secret: #{session.access_token.secret}
user_id: #{account_info["uid"]}
        MESSAGE
      end

      def create_new_session(app_key, app_secret)
        DropboxSession.new(app_key, app_secret)
      end

      def assert_answer!
        answer = STDIN.gets.strip
        exit if answer == "n"
      end
    end
  end
end
