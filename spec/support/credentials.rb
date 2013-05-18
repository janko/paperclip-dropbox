require "yaml"
require "erb"
require "active_support/core_ext/string/strip"
require "active_support/core_ext/hash/except"
require "active_support/core_ext/hash/keys"

CREDENTIAL_FILES = [:dropbox, :app_folder].inject({}) do |hash, access_type|
  hash.update(access_type => File.join(RSPEC_DIR, "#{access_type}.yml"))
end

CREDENTIALS = [:dropbox, :app_folder].inject({}) do |hash, access_type|
  if File.exists?(CREDENTIAL_FILES[access_type])
    content = File.read(CREDENTIAL_FILES[access_type])
    credentials = YAML.load(ERB.new(content).result).symbolize_keys
    hash.update(access_type => credentials)
  else
    hash.update(access_type => {})
  end
end

VCR.configure do |config|
  CREDENTIALS.each do |access_type, hash|
    hash.except(:access_type).each do |key, value|
      config.filter_sensitive_data("<#{key.capitalize}>") { value }
    end
  end

  config.before_record do |request|
    if not CREDENTIAL_FILES.values.all? &File.method(:exists?)
      $stderr.puts <<-EOS.strip_heredoc
        Some of the credential files were not found.  Please, copy spec/dropbox.yml.example
        into spec/dropbox.yml, and fill it with credentials of your Dropbox app with "full dropbox"
        access you intend to use. And the same for spec/app_folder.yml and "app folder" access.

        Make use of the "dropbox:authorize" Rake task.
      EOS
      raise
    end
  end
end
