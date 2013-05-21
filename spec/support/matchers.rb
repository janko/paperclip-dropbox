require "rest-client"

RSpec::Matchers.define :be_an_existing_url do
  match do |url|
    RestClient.get(url) do |response|
      case response.code
      when 200 then true
      when 404 then false
      else
        raise "Wrong error code: #{response.code}"
      end
    end
  end
end
