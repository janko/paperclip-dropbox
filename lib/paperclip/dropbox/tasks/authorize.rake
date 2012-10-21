require "rake"
require "paperclip/dropbox/rake" unless defined?(Paperclip::Dropbox::Rake)

namespace :dropbox do
  desc "Obtains your Dropbox credentials"
  task :authorize do
    if ENV["APP_KEY"].nil? or ENV["APP_SECRET"].nil?
      raise ArgumentError, "usage: `rake dropbox:authorize APP_KEY=your_app_key APP_SECRET=your_app_secret`"
    end
    Paperclip::Dropbox::Rake.authorize(ENV["APP_KEY"], ENV["APP_SECRET"])
  end
end
