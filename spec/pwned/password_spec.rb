RSpec.describe Pwned::Password do
  let(:password) { Pwned::Password.new("password") }

  it "initializes with a password" do
    expect(password.password).to eq("password")
  end

  it "doesn't initialize with an integer" do
    expect { Pwned::Password.new(123) }.to raise_error(TypeError)
  end

  it "doesn't initialize with an array" do
    expect { Pwned::Password.new(["hello", "world"]) }.to raise_error(TypeError)
  end

  it "doesn't initialize with a hash" do
    expect { Pwned::Password.new({ a: "b", c: "d" }) }.to raise_error(TypeError)
  end

  it "has a hashed version of the password" do
    expect(password.hashed_password).to eq("5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
  end

  describe "when pwned", pwned_range: "5BAA6" do
    it "reports it is pwned" do
      expect(password.pwned?).to be true
      expect(@stub).to have_been_requested
    end

    it "reports it has been pwned many times" do
      expect(password.pwned_count).to eq(3303003)
      expect(@stub).to have_been_requested
    end

    it "hashes password once" do
      expect(Digest::SHA1).to receive(:hexdigest).once.and_call_original
      expect(password.pwned?).to be true
      expect(@stub).to have_been_requested
    end

    it "works with simplified accessors" do
      expect(Pwned.pwned?(password.password)).to be true
      expect(Pwned.pwned_count(password.password)).to eq(3303003)
    end
  end

  describe "when not pwned", pwned_range: "37D5B" do
    let(:password) { Pwned::Password.new("t3hb3stpa55w0rd") }

    it "reports it is not pwned" do
      expect(password.pwned?).to be false
      expect(@stub).to have_been_requested
    end

    it "reports it has been pwned zero times" do
      expect(password.pwned_count).to eq(0)
      expect(@stub).to have_been_requested
    end

    it "works with simplified accessors" do
      expect(Pwned.pwned?(password.password)).to be false
      expect(Pwned.pwned_count(password.password)).to eq(0)
    end
  end

  describe "when the API times out" do
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_timeout
    end

    it "raises a custom error" do
      expect { password.pwned? }.to raise_error(&method(:verify_timeout_error))
      expect { password.pwned_count }.to raise_error(&method(:verify_timeout_error))
      expect(@stub).to have_been_requested.times(2)
    end

    def verify_timeout_error(error)
      aggregate_failures "testing custom error" do
        expect(error).to be_kind_of(Pwned::TimeoutError)
        expect(error.message).to match(/execution expired/)
        expect(error.cause).to be_kind_of(Net::OpenTimeout)
      end
    end
  end

  describe "when the API returns an error" do
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_return(status: 500)
    end

    it "raises a custom error" do
      expect { password.pwned? }.to raise_error(&method(:verify_internal_error))
      expect { password.pwned_count }.to raise_error(&method(:verify_internal_error))
      expect(@stub).to have_been_requested.times(2)
    end

    def verify_internal_error(error)
      aggregate_failures "testing custom error" do
        expect(error).to be_kind_of(Pwned::Error)
        expect(error.message).to match(/500/)
        expect(error.cause).to be_kind_of(Net::HTTPFatalError)
      end
    end
  end

  describe "when the API returns a 404" do
    # It shouldn't return a 404, but this tests it anyway.
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_return(status: 404)
    end

    it "raises a custom error" do
      expect { password.pwned? }.to raise_error(&method(:verify_not_found_error))
      expect { password.pwned_count }.to raise_error(&method(:verify_not_found_error))
      expect(@stub).to have_been_requested.times(2)
    end

    def verify_not_found_error(error)
      aggregate_failures "testing custom error" do
        expect(error).to be_kind_of(Pwned::Error)
        expect(error.message).to match(/404/)
        expect(error.cause).to be_kind_of(Net::HTTPServerException)
      end
    end
  end

  describe "advanced requests", pwned_range: "5BAA6" do
    it "sends a user agent with the current version" do
      password.pwned?

      expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").
        with(headers: { "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" })).
        to have_been_made.once
    end

    it "allows the user agent to be set" do
      password = Pwned::Password.new("password", headers: { "User-Agent" => "Super fun user agent" })
      password.pwned?

      expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").
        with(headers: { "User-Agent" => "Super fun user agent" })).
        to have_been_made.once
    end
  end

  describe 'streaming', pwned_range: "A0F41" do
    let(:password) { Pwned::Password.new("fake-password") }

    # Since our streaming is yielding by line across chunks, ensure we're not
    # missing lines by checking a single line file
    it "streams the whole file" do
      expect(password).to be_pwned
    end
  end

end
