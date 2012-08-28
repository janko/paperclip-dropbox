require 'rake'
require 'dropbox_sdk'

namespace :dropbox do
  desc "Obtain your access token"
  task :authorize do
    session = DropboxSession.new(ENV["APP_KEY"], ENV["APP_SECRET"])
    puts "Visit this URL: #{session.get_authorize_url}"
    print "And after you approved the authorization confirm it here (y/n): "
    answer = STDIN.gets.strip
    exit if answer == "n"
    session.get_access_token
    puts "Access token: #{session.access_token.key}"
    puts "Access token secret: #{session.access_token.secret}"
  end
end
