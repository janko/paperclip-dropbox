require "paperclip-dropbox"
require "vcr"

Dir[File.join(Bundler.root, "spec/support/**/*.rb")].each &method(:require)

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = {record: :new_episodes}
  config.configure_rspec_metadata!
end
