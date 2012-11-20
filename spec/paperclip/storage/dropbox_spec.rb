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

def reset_user_class
  if defined?(User)
    Object.send(:remove_const, 'User')
  end
  Object.const_set('User', Class.new(ActiveRecord::Base))
end

describe Paperclip::Storage::Dropbox, :vcr do
  before(:all) do
    ActiveRecord::Base.send(:include, Paperclip::Glue)

    FileUtils.rm_rf "tmp"
    FileUtils.mkdir_p "tmp"
    ActiveRecord::Base.establish_connection("sqlite3:///tmp/foo.sqlite3")
    CreateUsers.migrate(:up)
    reset_user_class

    Paperclip.options[:log] = false
  end

  def uploaded_file(filename, content_type)
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
        set_options(dropbox_credentials: CREDENTIALS_FILE)
        expect { User.new.avatar }.to_not raise_error(KeyError)
      end

      it "accepts an open file" do
        set_options(dropbox_credentials: File.open(CREDENTIALS_FILE))
        expect { User.new.avatar }.to_not raise_error(KeyError)
      end

      it "accepts a hash" do
        set_options(dropbox_credentials: CREDENTIALS)
        expect { User.new.avatar }.to_not raise_error(KeyError)
      end

      it "recognizes environments" do
        hash = YAML.load(ERB.new(File.read(CREDENTIALS_FILE)).result)

        set_options(dropbox_credentials: {development: hash}, dropbox_options: {environment: "development"})
        expect { User.new.avatar }.to_not raise_error(KeyError)

        set_options(dropbox_credentials: {development: hash}, dropbox_options: {environment: "production"})
        expect { User.new.avatar }.to raise_error(KeyError)
      end
    end

    describe "dropbox_options" do
      def set_options(options)
        stub_const("User", Class.new(ActiveRecord::Base) do
          has_attached_file :avatar,
            storage: :dropbox,
            dropbox_credentials: CREDENTIALS_FILE,
            dropbox_options: options,
            styles: {medium: "300x300"}
        end)
      end

      describe "path" do
        it "puts the instance in the scope, passes the style and appends the extension and style" do
          set_options(path: proc { |style| "#{style}/#{self.class.name}" })
          user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          "Public/original/User.jpg".should be_on_dropbox
          "Public/medium/User_medium.jpg".should be_on_dropbox
        end

        it "doesn't duplicate the extension" do
          set_options(path: proc { avatar.original_filename })
          user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          "Public/photo.jpg".should be_on_dropbox
        end

        it "has the #original_filename default" do
          set_options({})
          user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          "Public/photo.jpg".should be_on_dropbox
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
    before(:all) do
      class User < ActiveRecord::Base
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS_FILE
      end
    end

    it "handles files with spaces in their filename" do
      user = User.create(avatar: uploaded_file("photo with spaces.jpg", "image/jpeg"))
      "Public/photo_with_spaces.jpg".should be_on_dropbox
      user.destroy
      "Public/photo_with_spaces.jpg".should_not be_on_dropbox
    end

    after(:all) { reset_user_class }
  end

  describe "#url" do
    before(:all) do
      class User < ActiveRecord::Base
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS_FILE,
          styles: {medium: "300x300"}
      end
    end

    before(:each) { @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }

    it "returns nil when the file doesn't exist" do
      User.new.avatar.url.should be_nil
    end

    it "is valid" do
      response = Net::HTTP.get_response(URI.parse(@user.avatar.url))
      response.code.to_i.should == 200
      response = Net::HTTP.get_response(URI.parse(@user.avatar.url(:medium)))
      response.code.to_i.should == 200
    end

    it "defaults to original size" do
      File.basename(@user.avatar.url).should == "photo.jpg"
    end

    it "accepts the :download option" do
      response = Net::HTTP.get_response(URI.parse(@user.avatar.url(download: true)))
      response.code.to_i.should == 200
      response = Net::HTTP.get_response(URI.parse(@user.avatar.url(:medium, download: true)))
      response.code.to_i.should == 200
    end

    after(:all) { reset_user_class }
  end

  describe "CUD" do
    before(:all) do
      class User < ActiveRecord::Base
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: CREDENTIALS_FILE
      end
    end

    describe "create" do
      before(:each) { @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }

      it "puts the file on Dropbox" do
        "Public/photo.jpg".should be_on_dropbox
      end

      it "raises an exception on same filenames" do
        expect { User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }.to raise_error(Paperclip::Storage::Dropbox::FileExists)
      end
    end

    describe "update" do
      before(:each) { @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }

      it "deletes the old file if set to nil" do
        @user.update_attributes(avatar: nil)
        "Public/photo.jpg".should_not be_on_dropbox
      end

      it "deletes the old file and uploads the new one" do
        @user.update_attributes(avatar: uploaded_file("photo.jpg", "image/jpeg"))
        @user.update_attributes(avatar: uploaded_file("another_photo.jpg", "image/jpeg"))
        "Public/photo.jpg".should_not be_on_dropbox
        "Public/another_photo.jpg".should be_on_dropbox
      end
    end

    describe "destroy" do
      before(:each) { @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }

      it "deletes the uploaded file" do
        @user.destroy
        "Public/photo.jpg".should_not be_on_dropbox
      end

      it "doesn't raise errors if there are no files to delete" do
        @user.avatar.send(:dropbox_client).file_delete("Public/photo.jpg")
        expect { @user.destroy }.to_not raise_error
      end
    end

    after(:all) { reset_user_class }
  end

  after(:each) do
    User.destroy_all
  end

  after(:all) do
    ActiveRecord::Base.remove_connection
    FileUtils.rm_rf "tmp"
  end
end
