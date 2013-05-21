require "delegate"

module FileHelpers
  def uploaded_file(filename)
    file = File.open(File.join(Bundler.root, "spec/fixtures/files/#{filename}"))
    UploadedFile.new(file)
  end

  class UploadedFile < SimpleDelegator
    def content_type
      "text/plain"
    end

    def original_filename
      File.basename(path)
    end
  end
end

RSpec.configure do |config|
  config.include FileHelpers
end
