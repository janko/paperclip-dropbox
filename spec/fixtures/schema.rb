require "active_record"
require "paperclip"

ActiveRecord::Schema.define do
  create_table :posts, force: true do |t|
    t.attachment :attachment
  end
end
