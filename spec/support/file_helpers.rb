require "rack/test"

module FileHelpers
  def uploaded_file(filename, *rest)
    Rack::Test::UploadedFile.new(File.join(RSPEC_DIR, "fixtures/files/#{filename}"), *rest)
  end
end

RSpec.configure do |config|
  config.include FileHelpers
end
