require "spec_helper"
require "uri"

describe Paperclip::Storage::Dropbox::UrlGenerator do
  before do
    @options = {dropbox_credentials: CREDENTIALS[:dropbox]}
  end

  def new_post(options = {})
    Post.has_attached_file :attachment, @options
    Post.new({attachment: uploaded_file("photo.jpg")}.merge(options))
  end

  describe "#generate" do
    [:app_folder, :dropbox].each do |access_type|
      context "on \"#{access_type}\"", :vcr do
        before do
          @options.update(
            dropbox_credentials: CREDENTIALS[access_type],
            styles: {thumb: ""},
          )
        end

        it "generates a valid URL" do
          post = new_post.tap(&:save)
          expect(post.attachment.url).to be_an_existing_url
          expect(post.attachment.url(:thumb)).to be_an_existing_url
        end

        it "accepts the :download option" do
          post = new_post.tap(&:save)
          expect(post.attachment.url(download: true)).to match(/dl=1/)
          expect(post.attachment.url(download: true)).to be_an_existing_url
        end
      end
    end

    it "uses :default_url when the attachment isn't assigned" do
      @options.update(default_url: "/missing.png")
      post = new_post(attachment: nil)
      expect(post.attachment.url).to eq "/missing.png"
    end

    it "interpolates :default_url" do
      @options.update(default_url: "/:style/missing.png")
      post = new_post(attachment: nil)
      expect(post.attachment.url(:thumb)).to eq "/thumb/missing.png"
    end
  end
end
