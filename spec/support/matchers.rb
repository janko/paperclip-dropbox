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
