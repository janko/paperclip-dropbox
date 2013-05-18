require "spec_helper"

describe Paperclip::Storage::Dropbox, :vcr do
  before do
    User.has_attached_file :avatar
  end

  describe "integeration" do
    describe "creating" do
      it "puts the file on Dropbox" do
        @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
        expect(@user.avatar).to be_stored_as "Public/photo.jpg"
      end

      it "raises an exception on same filenames" do
        @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
        expect { User.create(avatar: uploaded_file("photo.jpg", "image/jpeg")) }.to raise_error(Paperclip::Storage::Dropbox::FileExists)
      end

      after do
        @user.destroy
      end
    end

    describe "updating" do
      before do
        @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
      end

      it "deletes the old file if set to nil" do
        @user.update_attributes(avatar: nil)
        expect(@user.avatar).not_to be_stored_as "Public/photo.jpg"
      end

      it "deletes the old file and uploads the new one" do
        @user.update_attributes(avatar: uploaded_file("another_photo.jpg", "image/jpeg"))

        expect(@user.avatar).to be_stored_as "Public/another_photo.jpg"
        expect(@user.avatar).not_to be_stored_as "Public/photo.jpg"
      end

      after do
        @user.destroy
      end
    end

    describe "destroying" do
      before do
        @user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))
      end

      it "deletes the uploaded file" do
        @user.destroy
        expect(@user.avatar).not_to be_stored_as "Public/photo.jpg"
      end

      it "doesn't raise errors if there are no files to delete" do
        @user.avatar.dropbox_client.file_delete("Public/photo.jpg")
        expect { @user.destroy }.not_to raise_error
      end
    end
  end
end
