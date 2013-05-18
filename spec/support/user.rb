require "active_record"
require "paperclip"

class CreateUsers < ActiveRecord::Migration
  self.verbose = false

  def change
    create_table :users do |t|
      t.attachment :avatar
    end
  end
end

class User < ActiveRecord::Base
  include Paperclip::Glue
end

RSpec.configure do |config|
  config.before(:all) do
    FileUtils.mkdir_p File.join(RSPEC_DIR, "../tmp")
    ActiveRecord::Base.establish_connection("sqlite3:///tmp/foo.sqlite3")
    CreateUsers.migrate(:up)
  end

  config.after(:all) do
    CreateUsers.migrate(:down)
    ActiveRecord::Base.remove_connection
  end
end
