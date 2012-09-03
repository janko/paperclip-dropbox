module Paperclip
  module Dropbox
    class Railtie < Rails::Railtie
      rake_tasks do
        load "paperclip/dropbox/tasks/authorize.rake"
      end
    end
  end
end
