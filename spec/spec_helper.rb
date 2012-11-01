require 'vcr'
require 'yaml'
require 'erb'
require 'active_support/core_ext/hash/keys'

RSPEC_DIR = File.expand_path(File.dirname(__FILE__))
Dir[File.join(RSPEC_DIR, "support/**/*.rb")].each { |f| require f }

CONFIG = YAML.load(File.read("#{RSPEC_DIR}/config.yml")).symbolize_keys

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :fakeweb
  config.default_cassette_options = {serialize_with: :syck}
  config.filter_sensitive_data('API_KEY')      { CONFIG[:app_key] }
  config.filter_sensitive_data('ACCESS_TOKEN') { CONFIG[:app_secret] }
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end
