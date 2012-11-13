module Paperclip
  module Dropbox
    class Railtie < Rails::Railtie
      rake_tasks do
        load "paperclip/dropbox/tasks.rake"
      end
    end
  end
end
