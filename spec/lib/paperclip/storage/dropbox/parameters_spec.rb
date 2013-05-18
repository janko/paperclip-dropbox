require "spec_helper"
require "active_support/core_ext/hash/keys"

describe Paperclip::Storage::Dropbox, :vcr do
  describe "parameters for #has_attached_file" do
    def set_options(options)
      User.has_attached_file :avatar, options
    end

    describe ":dropbox_credentials" do
      it "accepts a path to file" do
        set_options(dropbox_credentials: CREDENTIAL_FILES[:dropbox])
        expect { User.new.avatar }.not_to raise_error
      end

      it "accepts an open file" do
        set_options(dropbox_credentials: File.open(CREDENTIAL_FILES[:dropbox]))
        expect { User.new.avatar }.not_to raise_error
      end

      it "accepts a hash" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox])
        expect { User.new.avatar }.not_to raise_error
      end

      it "raises an error on invalid format" do
        set_options(dropbox_credentials: 1)
        expect { User.new.avatar }.to raise_error(ArgumentError)
      end

      it "raises an error if any of the keys are missing" do
        set_options(dropbox_credentials: {})
        expect { User.new.avatar }.to raise_error(KeyError)
      end

      it "raises an error if any credential is nil" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox].merge(app_key: nil))
        expect { User.new.avatar }.to raise_error
      end

      it "recognizes environments" do
        set_options(
          dropbox_credentials: {development: CREDENTIALS[:dropbox]},
          dropbox_options: {environment: "development"}
        )
        expect { User.new.avatar }.to_not raise_error(KeyError)

        set_options(
          dropbox_credentials: {development: CREDENTIALS[:dropbox]},
          dropbox_options: {environment: "production"}
        )
        expect { User.new.avatar }.to raise_error(KeyError)
      end

      it "uses the \"dropbox\" access type by default" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox].except(:access_type))
        expect(User.new.avatar.dropbox_client.instance_variable_get("@root")).to eq "dropbox"
      end

      it "uses the \"dropbox\" access type when specified" do
        set_options(dropbox_credentials: CREDENTIALS[:dropbox])
        expect(User.new.avatar.dropbox_client.instance_variable_get("@root")).to eq "dropbox"
      end

      it "uses the \"app_folder\" access type when specified" do
        set_options(dropbox_credentials: CREDENTIALS[:app_folder])
        expect(User.new.avatar.dropbox_client.instance_variable_get("@root")).to eq "sandbox"
      end
    end

    describe ":dropbox_options" do
      describe ":path" do
        it "evaluates itself in the scope of an instance" do
          set_options(
            dropbox_options: {path: ->(style) { "#{style}/#{self.class.name}" }},
            styles: {medium: "300x300"}
          )
          user = User.new(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          user.send(:save_attached_files)
          expect(user.avatar).to be_stored_as "Public/original/User.jpg"
          expect(user.avatar).to be_stored_as "Public/medium/User_medium.jpg"
        end

        it "has the #original_filename default" do
          set_options({})
          user = User.new(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          user.send(:save_attached_files)
          expect(user.avatar).to be_stored_as "Public/photo.jpg"
        end
      end

      describe ":unique_filename" do
        it "makes the file path unique" do
          set_options(dropbox_options: {unique_filename: true})
          User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
          expect { User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }.not_to raise_error

          User.destroy_all
        end
      end
    end
  end
end
