require "spec_helper"
require "rake"

describe "paperclip/dropbox/rake.rb" do
  it "loads the rake tasks when required" do
    expect { Rake::Task["dropbox:authorize"] }.to raise_error
    require "paperclip/dropbox/rake"
    expect { Rake::Task["dropbox:authorize"] }.to_not raise_error
  end
end
