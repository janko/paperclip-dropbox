require "spec_helper"

describe Paperclip::Storage::Dropbox::Credentials do
  describe "#fetch" do
    before do
      @it = described_class.new(CREDENTIALS[:dropbox])
    end

    it "parses the credentials" do
      @it.should_receive(:parse!)
      @it.fetch
    end

    it "validates the credentials" do
      @it.should_receive(:validate!)
      @it.fetch
    end

    it "returns the credentials" do
      expect(@it.fetch).to eq CREDENTIALS[:dropbox]
    end
  end

  describe "#parse!" do
    it "accepts a hash" do
      @it = described_class.new(CREDENTIALS[:dropbox])
      expect(@it.parse!).to eq CREDENTIALS[:dropbox]
    end

    it "accepts a path to file" do
      @it = described_class.new(CREDENTIAL_FILES[:dropbox])
      expect(@it.parse!).to eq CREDENTIALS[:dropbox]
    end

    it "accepts a pathname" do
      @it = described_class.new(Pathname.new(CREDENTIAL_FILES[:dropbox]))
      expect(@it.parse!).to eq CREDENTIALS[:dropbox]
    end

    it "accepts an open file" do
      @it = described_class.new(File.open(CREDENTIAL_FILES[:dropbox]))
      expect(@it.parse!).to eq CREDENTIALS[:dropbox]
    end

    it "raises an error on invalid credentials object" do
      @it = described_class.new(1)
      expect { @it.parse! }.to raise_error(ArgumentError)
    end

    it "fetches the namespace" do
      @it = described_class.new(namespace: CREDENTIALS[:dropbox])
      expect(@it.parse!(:namespace)).to eq CREDENTIALS[:dropbox]

      @it = described_class.new(namespace: CREDENTIALS[:dropbox])
      expect(@it.parse!("namespace")).to eq CREDENTIALS[:dropbox]
    end

    it "defaults to no namespace if the namespace doesn't exit" do
      @it = described_class.new(CREDENTIALS[:dropbox])
      expect(@it.parse!(:namespace)).to eq CREDENTIALS[:dropbox]
    end
  end

  describe "#validate!" do
    it "validates presence of keys" do
      @it = described_class.new(CREDENTIALS[:dropbox].except(:app_key))
      expect { @it.validate! }.to raise_error(KeyError)
    end

    it "validates presence of credentials" do
      @it = described_class.new(CREDENTIALS[:dropbox].merge(app_key: nil))
      expect { @it.validate! }.to raise_error(KeyError)
    end

    it "validates inclusion of :access_type" do
      @it = described_class.new(CREDENTIALS[:dropbox].merge(access_type: "foo"))
      expect { @it.validate! }.to raise_error(KeyError)
    end
  end
end
