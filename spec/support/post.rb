require "active_record"
require "nulldb"
require "paperclip"

class Post < ActiveRecord::Base
  include Paperclip::Glue

  def dynamic_dropbox_credentials
    {
      app_key: self.object_id,
      app_secret: self.object_id,
      access_type: 'dropbox',
      access_token: self.object_id,
      access_token_secret: self.object_id,
      user_id: self.object_id
    }
  end
end

RSpec.configure do |config|
  config.before(:all) do
    FileUtils.mkdir_p File.join(Bundler.root, "tmp")
    ActiveRecord::Base.establish_connection(
      adapter: "nulldb",
      schema: File.join(Bundler.root, "spec/fixtures/schema.rb"),
    )
  end

  config.after(:all) do
    ActiveRecord::Base.remove_connection
  end
end
