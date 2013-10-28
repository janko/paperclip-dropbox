require "paperclip-dropbox"
require "vcr"

Dir[File.join(Bundler.root, "spec/support/**/*.rb")].each &method(:require)

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end
