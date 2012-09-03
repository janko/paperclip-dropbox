require "spec_helper"
require 'paperclip/storage/dropbox'
require 'active_record'
require 'fileutils'
require 'rack/test'
require 'net/http'

describe Paperclip::Storage::Dropbox, :vcr do
  before(:all) do
    ActiveRecord::Base.send(:include, Paperclip::Glue)

    FileUtils.mkdir_p "tmp"
    ActiveRecord::Base.establish_connection("sqlite3:///tmp/foo.sqlite3")

    class CreateUsers < ActiveRecord::Migration
      self.verbose = false

      def change
        create_table :users do |t|
          t.attachment :avatar
        end
      end
    end
    CreateUsers.migrate(:up)

    Paperclip.options[:log] = false
  end

  CONTENT_TYPES = {
    "pdf" => "application/pdf"
  }

  def file(filename)
    extension = filename[/(?<=\.)\w{3,4}$/]
    content_type = CONTENT_TYPES[extension]
    path = "#{RSPEC_DIR}/files/#{filename}"
    Rack::Test::UploadedFile.new(path, content_type)
  end

  describe "arguments" do
    describe "dropbox_credentials" do
      before(:each) do
        class User < ActiveRecord::Base
          def self.add_dropbox_avatar(options = {})
            has_attached_file :avatar,
              {storage: :dropbox}.merge(options)
          end
        end
      end

      it "complains when not properly set" do
        User.add_dropbox_avatar(dropbox_credentials: 1)
        expect { User.new.avatar }.to raise_error(ArgumentError)
      end

      it "accepts a path to file" do
        path = "#{RSPEC_DIR}/dropbox.yml"
        User.add_dropbox_avatar(dropbox_credentials: path)
        User.new.avatar.should be_authenticated
      end

      it "accepts an open file" do
        file = File.open("#{RSPEC_DIR}/dropbox.yml")
        User.add_dropbox_avatar(dropbox_credentials: file)
        User.new.avatar.should be_authenticated
      end

      it "accepts a hash" do
        hash = YAML.load(ERB.new(File.read("#{RSPEC_DIR}/dropbox.yml")).result)
        User.add_dropbox_avatar(dropbox_credentials: hash)
        User.new.avatar.should be_authenticated
      end

      it "recognizes environments" do
        hash = YAML.load(ERB.new(File.read("#{RSPEC_DIR}/dropbox.yml")).result)

        User.add_dropbox_avatar(dropbox_credentials: {development: hash}, dropbox_options: {environment: "development"})
        User.new.avatar.should be_authenticated

        User.add_dropbox_avatar(dropbox_credentials: {development: hash}, dropbox_options: {environment: "production"})
        User.new.avatar.should_not be_authenticated
      end

      after(:each) do
        Object.send(:remove_const, :User)
      end
    end

    describe "dropbox_options" do
      before(:each) do
        class User < ActiveRecord::Base
          def self.add_dropbox_avatar(options = {})
            has_attached_file :avatar,
              storage: :dropbox,
              dropbox_credentials: "#{RSPEC_DIR}/dropbox.yml",
              dropbox_options: options,
              styles: {medium: "300x300"}
          end
        end
      end

      describe "path" do
        it "puts the instance in the scope, passes the style and appends the extension and style" do
          User.add_dropbox_avatar path: proc { |style| "#{style}/#{self.class.name}" }
          User.create(avatar: file("photo.jpg"))
          "Public/original/User.jpg".should be_on_dropbox
          "Public/medium/User_medium.jpg".should be_on_dropbox
        end

        it "doesn't duplicate the extension" do
          User.add_dropbox_avatar path: proc { avatar.original_filename }
          User.create(avatar: file("photo.jpg"))
          "Public/photo.jpg".should be_on_dropbox
        end

        it "has the #original_filename default" do
          User.add_dropbox_avatar({})
          User.create(avatar: file("photo.jpg"))
          "Public/photo.jpg".should be_on_dropbox
        end
      end

      describe "unique_filename" do
        it "makes the file path unique" do
          User.add_dropbox_avatar unique_filename: true
          User.create(avatar: file("photo.jpg"))
          expect { User.create(avatar: file("photo.jpg")) }.to_not raise_error(Paperclip::Storage::Dropbox::FileExists)
        end
      end

      after(:each) do
        User.destroy_all
        Object.send(:remove_const, :User)
      end
    end
  end

  describe "#url" do
    before(:all) do
      class User < ActiveRecord::Base
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: "#{RSPEC_DIR}/dropbox.yml",
          styles: {medium: "300x300"}
      end

      @user = User.create(avatar: file("photo.jpg"))
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

    after(:all) do
      User.destroy_all
      Object.send(:remove_const, :User)
    end
  end

  describe "CUD" do
    before(:all) do
      class User < ActiveRecord::Base
        has_attached_file :avatar,
          storage: :dropbox,
          dropbox_credentials: "#{RSPEC_DIR}/dropbox.yml"
      end
    end

    describe "create" do
      before(:each) do
        User.create(avatar: file("photo.jpg"))
      end

      it "puts the file on Dropbox" do
        "Public/photo.jpg".should be_on_dropbox
      end

      it "raises an exception on same filenames" do
        expect { User.create(avatar: file("photo.jpg")) }.to raise_error(Paperclip::Storage::Dropbox::FileExists)
      end

      after(:each) do
        User.destroy_all
      end
    end

    describe "update" do
      before(:each) do
        User.create(avatar: file("photo.jpg"))
      end

      it "deletes the old file if set to nil" do
        User.first.update_attributes(avatar: nil)
        "Public/photo.jpg".should_not be_on_dropbox
      end

      it "deletes the old file and uploads the new one" do
        User.first.update_attributes(avatar: file("another_photo.jpg"))
        "Public/photo.jpg".should_not be_on_dropbox
        "Public/another_photo.jpg".should be_on_dropbox
      end

      after(:each) do
        User.destroy_all
      end
    end

    describe "destroy" do
      before(:each) do
        User.create(avatar: file("photo.jpg"))
      end

      it "deletes the uploaded file" do
        User.first.destroy
        "Public/photo.jpg".should_not be_on_dropbox
      end

      it "doesn't raise errors if there are no files to delete" do
        User.first.avatar.send(:dropbox_client).file_delete("Public/photo.jpg")
        expect { User.first.destroy }.to_not raise_error
      end

      after(:each) do
        User.destroy_all
      end
    end

    after(:all) do
      Object.send(:remove_const, :User)
    end
  end

  after(:all) do
    ActiveRecord::Base.remove_connection
    FileUtils.rm_rf "tmp"
  end
end
