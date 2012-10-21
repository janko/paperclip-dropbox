require "rake"
require "paperclip/dropbox/rake" unless defined?(Paperclip::Dropbox::Rake)

namespace :dropbox do
  desc "Obtains your Dropbox credentials"
  task :authorize do
    Paperclip::Dropbox::Rake.authorize(ENV["APP_KEY"], ENV["APP_SECRET"])
  end
end
