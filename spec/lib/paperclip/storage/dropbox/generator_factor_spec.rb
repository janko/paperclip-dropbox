require "spec_helper"
require "paperclip/storage/dropbox/generator_factory"

describe Paperclip::Storage::Dropbox::GeneratorFactory do
  it "should build a private url generator" do
    described_class.build_url_generator(double(:storage), {
      dropbox_credentials: {access_type: "app_folder"}}).should be_a(Paperclip::Storage::Dropbox::PrivateUrlGenerator)
  end

  it "should build a private url generator" do
     described_class.build_url_generator(double(:storage), {
       dropbox_credentials: { access_type: "dropbox" },
       dropbox_visibility: 'private'}).should be_a(Paperclip::Storage::Dropbox::PrivateUrlGenerator)
  end

  it "should build a public url generator" do
     described_class.build_url_generator(double(:storage), {
       dropbox_credentials: { access_type: "dropbox" },
       dropbox_visibility: 'public'}).should be_a(Paperclip::Storage::Dropbox::PublicUrlGenerator)
  end
end

