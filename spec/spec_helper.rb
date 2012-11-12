require 'vcr'
require 'yaml'
require 'erb'
require 'active_support/core_ext/hash/keys'

RSPEC_DIR = File.expand_path(File.dirname(__FILE__))
Dir[File.join(RSPEC_DIR, "support/**/*.rb")].each { |f| require f }

CREDENTIALS_FILE = "#{RSPEC_DIR}/dropbox.yml"

if File.exists?(CREDENTIALS_FILE)
  CREDENTIALS = YAML.load(ERB.new(File.read(CREDENTIALS_FILE)).result).symbolize_keys
else
  puts <<-EOS

### ERROR ###
Credential file not found at #{CREDENTIALS_FILE}.
Copy dropbox.yml.example and fill in your credentials.

  EOS
  exit
end


RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :fakeweb
  CREDENTIALS.keys.each do |key|
    config.filter_sensitive_data("<#{key.to_s.upcase}>") { CREDENTIALS[key] }
  end
  config.default_cassette_options = {
    serialize_with: :syck,
    record: :new_episodes
  }
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end
