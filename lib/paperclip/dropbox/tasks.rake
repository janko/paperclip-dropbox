require "paperclip/dropbox/rake"

namespace :dropbox do
  desc "Obtains your Dropbox credentials"
  task :authorize do
    if ENV["APP_KEY"].nil? or ENV["APP_SECRET"].nil?
      puts "USAGE: `rake dropbox:authorize APP_KEY=your_app_key APP_SECRET=your_app_secret` ACCESS_TYPE=your_access_type"
      exit
    end

    Paperclip::Dropbox::Rake.authorize(ENV["APP_KEY"], ENV["APP_SECRET"], ENV["ACCESS_TYPE"] || "dropbox")
  end
end
