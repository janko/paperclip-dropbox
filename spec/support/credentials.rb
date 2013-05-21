require "vcr"
require "yaml"
require "erb"
require "active_support/core_ext/string/strip"
require "active_support/core_ext/hash/except"
require "active_support/core_ext/hash/keys"

CREDENTIAL_FILES = [:dropbox, :app_folder].inject({}) do |hash, access_type|
  hash.update(access_type => File.join(Bundler.root, "spec/#{access_type}.yml"))
end

CREDENTIALS = [:dropbox, :app_folder].inject({}) do |hash, access_type|
  begin
    content = File.read(CREDENTIAL_FILES[access_type])
    credentials = YAML.load(ERB.new(content).result).symbolize_keys
    hash.update(access_type => credentials)
  rescue Errno::ENOENT
    $stderr.puts <<-EOS.strip_heredoc

      Some of the credential files were not found.  Please, copy spec/dropbox.yml.example
      into spec/dropbox.yml, and fill it with credentials of your Dropbox app with "full dropbox"
      access you intend to use. And the same for spec/app_folder.yml and "app folder" access.

      Make use of the "dropbox:authorize" Rake task.

    EOS
    exit
  end
end

VCR.configure do |config|
  CREDENTIALS.each do |access_type, hash|
    hash.except(:access_type).each do |key, value|
      config.filter_sensitive_data("<#{key.upcase}>") { value }
    end
  end
end
