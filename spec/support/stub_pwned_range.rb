RSpec.configure do |config|
  config.around :example, :pwned_range do |example|
    pwned_range = example.metadata[:pwned_range]
    File.open(File.expand_path("../fixtures/#{pwned_range}.txt", __dir__)) do |body|
      uri = "https://api.pwnedpasswords.com/range/#{pwned_range}"
      @stub = stub_request(:get, uri).to_return(body: body)
      example.run
    end
  end
end
