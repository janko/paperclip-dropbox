require "spec_helper"

describe Paperclip::Storage::Dropbox::PathGenerator do
  before do
    @options = {dropbox_credentials: CREDENTIALS[:app_folder]}
  end

  def new_post(options = {})
    Post.has_attached_file :attachment, @options
    Post.validates_attachment_content_type :attachment, :content_type => %w(image/jpeg image/jpg image/png)
    Post.new({attachment: uploaded_file("photo.jpg")}.merge(options))
  end

  describe "#generate" do
    it "defaults to filename" do
      expect(new_post.attachment.path).to eq "photo.jpg"
    end

    context "when path is a string" do
      before do
        @options.update(path: ":style/:class_:filename")
      end

      it "interpolates with Paperclip's interpolator" do
        expect(new_post.attachment.path(:medium)).to eq "medium/posts_photo.jpg"
      end
    end

    context "when path is a proc" do
      before do
        @options.update(dropbox_options: {
          path: ->(style) { "#{style}/#{attachment.original_filename}" }
        })
      end

      it "evaluates the proc in context of the instance" do
        expect(new_post.attachment.path).to eq "original/photo.jpg"
      end

      it "appends the style if present" do
        expect(new_post.attachment.path(:medium)).to eq "medium/photo_medium.jpg"
        expect(new_post.attachment.path).to eq "original/photo.jpg"
      end
    end

    it "prepends 'Public' when the access type is full dropbox" do
      @options.update(dropbox_credentials: CREDENTIALS[:dropbox])
      expect(new_post.attachment.path).to eq "Public/photo.jpg"
    end

    it "assigns a unique path when :unique_filename options is passed" do
      @options.update(dropbox_options: {unique_filename: true})
      post1 = new_post
      post2 = new_post
      post1.id = 1
      post1.id = 2

      expect(post1.attachment.path).not_to eq post2.attachment.path
    end
  end
end
