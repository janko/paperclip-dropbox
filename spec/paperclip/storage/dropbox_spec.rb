require "spec_helper"
require 'paperclip-dropbox'
require 'active_record'
require 'fileutils'
require 'rack/test'
require 'net/http'

class CreateUsers < ActiveRecord::Migration
  self.verbose = false

  def change
    create_table :users do |t|
      t.attachment :avatar
    end
  end
end

describe Paperclip::Storage::Dropbox, :vcr do
  before(:all) do
    ActiveRecord::Base.send(:include, Paperclip::Glue)

    FileUtils.rm_rf "tmp"
    FileUtils.mkdir_p "tmp"
    ActiveRecord::Base.establish_connection("sqlite3:///tmp/foo.sqlite3")
    CreateUsers.migrate(:up)

    Paperclip.options[:log] = false
  end

  def uploaded_file(filename, content_type = "text/plain")
    Rack::Test::UploadedFile.new("#{RSPEC_DIR}/files/#{filename}", content_type)
  end

  describe "arguments for #has_attached_file" do
    describe "dropbox_credentials" do
      def set_options(options)
        stub_const("User", Class.new(ActiveRecord::Base) do
          has_attached_file :avatar,
            {storage: :dropbox}.merge(options)
        end)
      end

      it "complains when not properly set" do
        set_options(dropbox_credentials: 1)
        expect { User.new.avatar }.to raise_error(ArgumentError)

        set_options(dropbox_credentials: {})
        expect { User.new.avatar }.to raise_error(KeyError)
      end

      it "accepts a path to file" do
        set_options(dropbox_credentials: CREDENTIALS_FILE[:dropbox])
        expect { User.new.avatar }.to_not raise_error(KeyError)
      end

      it "accepts an open file" do
        set_options(dropbox_credentials: File.open(CREDENTIALS_FILE[:dropbox]))
        expect { User.new.avatar }.to_not raise_error(KeyError)
      end

      it "accepts a hash" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox])
        expect { User.new.avatar }.to_not raise_error(KeyError)
      end

      it "recognizes environments" do
        set_options(
          dropbox_credentials: { development: CREDENTIALS[:dropbox] },
          dropbox_options: { environment: "development" }
        )
        expect { User.new.avatar }.to_not raise_error(KeyError)

        set_options(
          dropbox_credentials: { development: CREDENTIALS[:dropbox] },
          dropbox_options: { environment: "production" }
        )
        expect { User.new.avatar }.to raise_error(KeyError)
      end

      it "uses the dropbox access type by default" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox].except(:access_type))
        expect { User.create(avatar: uploaded_file("test_file")) }.to_not raise_error
      end

      it "uses the dropbox access type when specified" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox])
        user = User.create(avatar: uploaded_file("test_file"))
        user.avatar.dropbox_metadata['root'].should == 'dropbox'
      end

      it "uses the app_folder access type when specified" do
        set_options(dropbox_credentials: CREDENTIALS[:app_folder])
        user = User.create(avatar: uploaded_file("test_file"))
        user.avatar.dropbox_metadata['root'].should == 'app_folder'
      end

      it "complains when given an invalid access type" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox].merge(access_type: 'x'))
        expect { User.new.avatar }.to raise_error(KeyError)
      end
    end

    describe "dropbox_options" do
      def set_options(options, styles = {})
        stub_const("User", Class.new(ActiveRecord::Base) do
          has_attached_file :avatar,
            storage: :dropbox,
            dropbox_credentials: CREDENTIALS[:dropbox],
            dropbox_options: options,
            styles: styles
        end)
      end

      describe "path" do
        it "puts the instance in the scope, passes the style and appends the extension and style" do
          set_options(
            { path: proc { |style| "#{style}/#{self.class.name}" } },
            { medium: "300x300" }
          )
          user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          user.avatar.should be_stored_as "Public/original/User.jpg"
          user.avatar.should be_stored_as "Public/medium/User_medium.jpg"
        end

        it "doesn't duplicate the extension" do
          set_options(path: proc { avatar.original_filename })
          user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          user.avatar.should be_stored_as "Public/photo.jpg"
        end

        it "has the #original_filename default" do
          set_options({})
          user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          user.avatar.should be_stored_as "Public/photo.jpg"
        end
      end

      describe "unique_filename" do
        it "makes the file path unique" do
          set_options(unique_filename: true)
          user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          expect { User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }.to_not raise_error(Paperclip::Storage::Dropbox::FileExists)
        end
      end
    end
  end

  describe "setter" do
    before(:each) do
      stub_const("User", Class.new(ActiveRecord::Base) do
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS[:dropbox]
      end)
    end

    it "handles files with spaces in their filename" do
      user = User.create(avatar: uploaded_file("photo with spaces.jpg", "image/jpeg"))
      user.avatar.should be_stored_as "Public/photo_with_spaces.jpg"
      user.destroy
      user.avatar.should_not be_stored_as "Public/photo_with_spaces.jpg"
    end
  end

  describe "#url" do
    def set_access_type(access_type)
      stub_const("User", Class.new(ActiveRecord::Base) do
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS_FILE[access_type],
          styles: { medium: "300x300" },
          default_url: "http://some-url.com"
      end)
    end

    it "returns :default_url when the file doesn't exist" do
      set_access_type(:dropbox)
      User.new.avatar.url.should eq "http://some-url.com"
      User.new.avatar.url(:medium).should eq "http://some-url.com"
    end

    it "returns the default style when no style is provided" do
      set_access_type(:dropbox)
      @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))

      File.basename(@user.avatar.url).should == "photo.jpg"
    end

    [:dropbox, :app_folder].each do |access_type|
      it "returns valid download URLs in #{access_type} access mode" do
        set_access_type(access_type)
        @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))

        [false, true].each do |download_option|
          response = RestClient.get @user.avatar.url(download: download_option)
          response.code.should == 200

          response = RestClient.get @user.avatar.url(:medium, download: download_option)
          response.code.should == 200
        end
      end
    end
  end

  describe "#path" do
    def set_access_type(access_type)
      stub_const("User", Class.new(ActiveRecord::Base) do
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS_FILE[access_type]
      end)
    end

    it "delegates to #path_for_url when using app_folder access" do
      set_access_type(:app_folder)
      user = User.new(avatar: uploaded_file("test_file"))
      style = user.avatar.default_style

      user.avatar.path(style).should == user.avatar.path_for_url(style)
    end

    it "prepends 'Public' when using full dropbox access" do
      set_access_type(:dropbox)
      user = User.new(avatar: uploaded_file("test_file"))
      style = user.avatar.default_style

      user.avatar.path(style).should == "Public/#{user.avatar.path_for_url(style)}"
    end
  end

  describe "#path_for_url" do
    def set_options(options)
      stub_const("User", Class.new(ActiveRecord::Base) do
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS_FILE[:dropbox],
          dropbox_options: options
      end)
    end

    it "handles files with varying extension lengths" do
      set_options({})
      ["test_file", "test_file.c", "test_file.markdown"].each do |filename|
        user = User.new(avatar: uploaded_file(filename))
        user.avatar.path_for_url(user.avatar.default_style).should == filename
      end
    end

    it "appends the style name, preserving the extension if one exists" do
      set_options({})

      user = User.new(avatar: uploaded_file("test_file.c"))
      user.avatar.path_for_url(:dummy).should == "test_file_dummy.c"

      user = User.new(avatar: uploaded_file("test_file"))
      user.avatar.path_for_url(:dummy).should == "test_file_dummy"
    end

    it "uses the result of the path proc if one is provided" do
      set_options(path: proc { |style| "avatars/#{style}/filename" })
      user = User.new(avatar: uploaded_file("test_file"))
      user.avatar.path_for_url(:dummy).should == "avatars/dummy/filename_dummy"
    end

    it "executes the path proc in the context of the model instance" do
      set_options(path: proc { |style| "#{self.class.name}" })
      user = User.new(avatar: uploaded_file("test_file"))
      user.avatar.path_for_url(user.avatar.default_style).should == "User"
    end

    it "makes the path unique per model if unique_filename is set" do
      set_options(unique_filename: true)
      user1 = User.new(avatar: uploaded_file("test_file"))
      user2 = User.new(avatar: uploaded_file("test_file"))
      user1.id = 1
      user2.id = 2

      user1.avatar.path_for_url(:dummy).
        should_not == user2.avatar.path_for_url(:dummy)
    end
  end

  describe "CUD" do
    before(:each) do
      stub_const("User", Class.new(ActiveRecord::Base) do
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS[:dropbox]
      end)

      @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
    end

    describe "create" do
      it "puts the file on Dropbox" do
        @user.avatar.should be_stored_as "Public/photo.jpg"
      end

      it "raises an exception on same filenames" do
        expect { User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }.to raise_error(Paperclip::Storage::Dropbox::FileExists)
      end
    end

    describe "update" do
      it "deletes the old file if set to nil" do
        @user.update_attributes(avatar: nil)
        @user.avatar.should_not be_stored_as "Public/photo.jpg"
      end

      it "deletes the old file and uploads the new one" do
        @user.update_attributes(avatar: uploaded_file("photo.jpg", "image/jpeg"))
        @user.update_attributes(avatar: uploaded_file("another_photo.jpg", "image/jpeg"))

        @user.avatar.should_not be_stored_as "Public/photo.jpg"
        @user.avatar.should be_stored_as "Public/another_photo.jpg"
      end
    end

    describe "destroy" do
      it "deletes the uploaded file" do
        @user.destroy
        @user.avatar.should_not be_stored_as "Public/photo.jpg"
      end

      it "doesn't raise errors if there are no files to delete" do
        @user.avatar.dropbox_client.file_delete("Public/photo.jpg")
        expect { @user.destroy }.to_not raise_error
      end
    end
  end

  after(:each) do
    if defined?(User)
      User.destroy_all
    end
  end

  after(:all) do
    ActiveRecord::Base.remove_connection
    FileUtils.rm_rf "tmp"
  end
end
