require 'vcr'
require 'yaml'
require 'erb'
require 'active_support/core_ext/hash/keys'

RSPEC_DIR = File.expand_path(File.dirname(__FILE__))
Dir[File.join(RSPEC_DIR, "support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/vcr_cassettes'
  config.hook_into :fakeweb
  config.default_cassette_options = {serialize_with: :syck}
  config.filter_sensitive_data('API_KEY')      { ENV['DROPBOX_APP_KEY'] }
  config.filter_sensitive_data('ACCESS_TOKEN') { ENV['DROPBOX_ACCESS_TOKEN'] }
  config.configure_rspec_metadata!
  config.allow_http_connections_when_no_cassette = true
end

RSpec::Matchers.define :be_on_dropbox do
  match do |filename|
    begin
      !!dropbox_client.media(filename)
    rescue DropboxError
      false
    end
  end

  def dropbox_client
    @dropbox_client ||= begin
      settings = YAML.load(ERB.new(File.read("#{RSPEC_DIR}/dropbox.yml")).result).symbolize_keys
      session = DropboxSession.new(settings[:app_key], settings[:app_secret]).tap do |session|
        session.set_access_token(settings[:access_token], settings[:access_token_secret])
      end
      DropboxClient.new(session, :dropbox)
    end
  end
end

RSpec::Matchers.define :be_authenticated do
  match do |attachment|
    begin
      attachment.send(:dropbox_client).account_info
      true
    rescue
      false
    end
  end

  failure_message_for_should do |attachment|
    begin
      attachment.send(:dropbox_client).account_info
    rescue DropboxError => exception
      "expected #{attachment.name} to be authenticated, but exception \"#{exception}\" was raised"
    end
  end

  failure_message_for_should_not do |attachment|
    "expected #{attachment.name} to not be authenticated"
  end
end
