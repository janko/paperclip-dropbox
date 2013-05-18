require "spec_helper"
require "net/http"
require "uri"

describe Paperclip::Storage::Dropbox, :vcr do
  before(:each) do
    User.has_attached_file :avatar
  end

  def set_options(options)
    User.has_attached_file :avatar, options
  end

  describe "#=" do
    it "handles files with spaces in their filename" do
      user = User.create(avatar: uploaded_file("photo with spaces.jpg", "image/jpeg"))
      expect(user.avatar).to be_stored_as "Public/photo_with_spaces.jpg"
      user.destroy
      expect(user.avatar).not_to be_stored_as "Public/photo_with_spaces.jpg"
    end
  end

  describe "#url" do
    def path(value)
      URI.parse(URI.encode(value)).request_uri
    end

    it "returns :default_url when the file doesn't exist" do
      set_options(default_url: "http://some-url.com", styles: {medium: "300x300"})
      expect(User.new.avatar.url).to eq "http://some-url.com"
      expect(User.new.avatar.url(:medium)).to eq "http://some-url.com"
    end

    it "returns the default style when no style is provided" do
      user = User.new(avatar: uploaded_file("photo.jpg", "image/jpeg"))
      expect(File.basename(user.avatar.url)).to eq "photo.jpg"
    end

    [:dropbox, :app_folder].each do |access_type|
      it "returns valid download URL in \"#{access_type}\" access mode" do
        set_options(dropbox_credentials: CREDENTIALS[access_type], styles: {medium: "300x300"})
        user = User.create(avatar: uploaded_file("photo.jpg", "image/jpeg"))

        [false, true].each do |download_option|
          Net::HTTP.start("dl.dropboxusercontent.com", use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
            response = http.request_get path(user.avatar.url(download: download_option))
            expect(response.code.to_i).to eq 200

            response = http.request_get path(user.avatar.url(:medium, download: download_option))
            expect(response.code.to_i).to eq 200
          end
        end

        user.destroy
      end
    end
  end

  describe "#path" do
    it "delegates to #path_for_url when using app_folder access" do
      set_options(dropbox_credentials: CREDENTIALS[:app_folder])
      user = User.new(avatar: uploaded_file("test_file"))
      expect(user.avatar.path).to eq user.avatar.path_for_url
    end

    it "prepends \"Public\" when using full dropbox access" do
      set_options(dropbox_credentials: CREDENTIALS[:dropbox])
      user = User.new(avatar: uploaded_file("test_file"))
      expect(user.avatar.path).to eq "Public/#{user.avatar.path_for_url}"
    end
  end

  describe "#path_for_url" do
    it "handles files with varying extension lengths" do
      ["test_file", "test_file.c", "test_file.markdown"].each do |filename|
        user = User.new(avatar: uploaded_file(filename))
        expect(user.avatar.path_for_url).to eq filename
      end
    end

    it "appends the style name, preserving the extension if one exists" do
      user = User.new(avatar: uploaded_file("test_file.c"))
      expect(user.avatar.path_for_url(:dummy)).to eq "test_file_dummy.c"

      user = User.new(avatar: uploaded_file("test_file"))
      expect(user.avatar.path_for_url(:dummy)).to eq "test_file_dummy"
    end

    it "uses the result of the :path proc if one is provided" do
      set_options(dropbox_options: {path: ->(style) { "avatars/#{style}/filename" }})
      user = User.new(avatar: uploaded_file("test_file"))
      expect(user.avatar.path_for_url(:dummy)).to eq "avatars/dummy/filename_dummy"
    end

    it "executes the path proc in the context of the model instance" do
      set_options(dropbox_options: {path: ->(style) { self.class.name }})
      user = User.new(avatar: uploaded_file("test_file"))
      expect(user.avatar.path_for_url).to eq "User"
    end
  end
end
