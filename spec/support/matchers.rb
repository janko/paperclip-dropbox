RSpec::Matchers.define :be_stored_as do |path|
  match do |attachment|
    metadata = attachment.send(:dropbox_client).metadata(path)
    !metadata.nil? && !metadata['is_deleted']
  end

  failure_message_for_should do |attachment|
    "expected file to exist at Dropbox path \"#{path}\""
  end

  failure_message_for_should_not do |attachment|
    "expected no file to exist at Dropbox path \"#{path}\""
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
