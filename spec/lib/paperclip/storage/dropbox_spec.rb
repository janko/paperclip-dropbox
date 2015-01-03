require "spec_helper"
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/except"
require "active_support/core_ext/hash/keys"

describe Paperclip::Storage::Dropbox, :vcr do
  before do
    @options = {}
  end

  def new_post(options = {})
    Post.has_attached_file :attachment,
      {dropbox_credentials: CREDENTIALS[:dropbox]}.deep_merge(@options)
    Post.validates_attachment_content_type :attachment, :content_type => %w(image/jpeg image/jpg image/png)
    Post.new({attachment: uploaded_file("photo.jpg")}.merge(options))
  end

  it "defaults to public dropbox storage" do
    @options.merge!(dropbox_credentials: {access_type: nil})
    expect(new_post.attachment.dropbox_client.root).to eq "dropbox"
    expect(new_post.attachment.public_dropbox?).to eq true
  end

  describe "#dropbox_client" do
    it "initializes a Dropbox client with credentials" do
      client = new_post.attachment.dropbox_client
      credentials = CREDENTIALS[:dropbox]
      expect(client.session.consumer_key).to eq credentials[:app_key]
      expect(client.session.consumer_secret).to eq credentials[:app_secret]
      expect(client.session.access_token.key).to eq credentials[:access_token]
      expect(client.session.access_token.secret).to eq credentials[:access_token_secret]
      expect(client.root).to eq({"dropbox" => "dropbox", "app_folder" => "sandbox"}[credentials[:access_type]])
    end

    it "defaults :access_type to 'dropbox'" do
      @options.update(dropbox_credentials: CREDENTIALS[:dropbox].except(:access_type))
      expect(new_post.attachment.dropbox_client.root).to eq "dropbox"
    end

    it "initiatlizes a Dropbox client with proc/lambda credentials" do
      Post.has_attached_file :attachment, {
        dropbox_credentials: Proc.new { |post_class|
          post_class.instance.dynamic_dropbox_credentials
        }
      }.deep_merge(@options)
      Post.validates_attachment_content_type :attachment, :content_type => %w(image/jpeg image/jpg image/png)

      post = Post.new({attachment: uploaded_file("photo.jpg")})
      client = post.attachment.dropbox_client

      expect(client.session.consumer_key).to eq post.object_id
      expect(client.session.consumer_secret).to eq post.object_id
      expect(client.session.access_token.key).to eq post.object_id
      expect(client.session.access_token.secret).to eq post.object_id

      post_2 = Post.new({attachment: uploaded_file("photo.jpg")})
      client_2 = post_2.attachment.dropbox_client

      expect(client_2.object_id).to_not eq client.object_id

      expect(client_2.session.consumer_key).to eq post_2.object_id
      expect(client_2.session.consumer_secret).to eq post_2.object_id
      expect(client_2.session.access_token.key).to eq post_2.object_id
      expect(client_2.session.access_token.secret).to eq post_2.object_id
    end

  end

  describe "#flush_writes" do
    it "uploads the attachment to Dropbox" do
      post = new_post.tap(&:save)
      expect(post.attachment.url).to be_an_existing_url
    end

    it "handles spaces in filenames" do
      post = new_post(attachment: uploaded_file("photo with spaces.jpg")).tap(&:save)
      expect(post.attachment.url).to be_an_existing_url
    end
  end

  describe "#flush_deletes" do
    it "deletes the attachment from Dropbox" do
      post = new_post.tap(&:save)
      url = post.attachment.url
      post.destroy
      expect(url).not_to be_an_existing_url
    end

    it "doesn't raise errors when file doesn't exist on Dropbox" do
      post = new_post.tap(&:save)
      post.attachment.dropbox_client.file_delete(post.attachment.path)
      expect { post.destroy }.not_to raise_error
    end

    it "handles spaces in filenames" do
      post = new_post(attachment: uploaded_file("photo with spaces.jpg")).tap(&:save)
      url = post.attachment.url
      post.destroy
      expect(url).not_to be_an_existing_url
    end
  end

  describe "#exists?" do
    it "returns true if the file exists on Dropbox" do
      post = new_post.tap(&:save)
      expect(post.attachment.exists?).to be_true
    end

    it "returns false if the file doesn't exist on Dropbox" do
      post = new_post
      expect(post.attachment.exists?).to be_false
    end

    it "returns false if the attachment is blank" do
      post = new_post(attachment: nil)
      expect(post.attachment.exists?).to be_false
    end
  end

  describe "path" do
    it "adds 'Public' to path" do
        @options.update(dropbox_visibility: "public")
        new_post.attachment.path.include?("Public").should == true
    end

    it "does not add 'Public' to path" do
        @options.update(dropbox_visibility: "private")
        new_post.attachment.path.include?("Public").should == false
    end

    it "does not add 'Public' to app_folder path" do
      @options.update(dropbox_credentials: CREDENTIALS[:dropbox].merge(:access_type => "app_folder"))
      @options.update(dropbox_visibility: "public")
      new_post.attachment.path.include?("Public").should == false
    end
  end

  describe "#copy_to_local_file" do
    it "copies file from Dropbox to a local file" do
      post = new_post.tap(&:save)
      destination = File.join(Bundler.root, "tmp/photo.jpg")
      post.attachment.copy_to_local_file(destination)
      expect(File.exists?(destination)).to be_true
      File.delete(destination)
    end
  end
end
