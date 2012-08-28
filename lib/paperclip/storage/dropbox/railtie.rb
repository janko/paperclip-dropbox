module Paperclip
  module Storage
    module Dropbox
      class Railtie < Rails::Railtie
        rake_tasks do
          load "tasks/paperclip-dropbox.rake"
        end
      end
    end
  end
end
