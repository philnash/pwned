RSpec.describe Pwned::Password do
  let(:password) { Pwned::Password.new("password") }

  it "initializes with a password" do
    expect(password.password).to eq("password")
  end

  it "has a hashed version of the password" do
    expect(password.hashed_password).to eq("5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
  end

  describe "when pwned" do
    before(:example) do
      file = File.new('./spec/fixtures/5BAA6.txt')
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_return(body: file)
    end

    it "reports it is pwned" do
      expect(password.pwned?).to be true
      expect(@stub).to have_been_requested
    end

    it "reports it has been pwned many times" do
      expect(password.pwned_count).to eq(3303003)
      expect(@stub).to have_been_requested
    end
  end

  describe "when not pwned" do
    let(:password) { Pwned::Password.new("t3hb3stpa55w0rd") }

    before(:example) do
      file = File.new('./spec/fixtures/37D5B.txt')
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/37D5B").to_return(body: file)
    end

    it "reports it is not pwned" do
      expect(password.pwned?).to be false
      expect(@stub).to have_been_requested
    end

    it "reports it has been pwned zero times" do
      expect(password.pwned_count).to eq(0)
      expect(@stub).to have_been_requested
    end
  end

  describe "when the API times out" do
    before(:example) do
      file = File.new('./spec/fixtures/37D5B.txt')
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_timeout
    end

    it "raises a custom error" do
      expect { password.pwned? }.to raise_error(Pwned::TimeoutError)
      expect { password.pwned_count }.to raise_error(Pwned::TimeoutError)
      expect(@stub).to have_been_requested.times(2)
    end
  end

  describe "when the API returns an error" do
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_return(status: 500)
    end

    it "raises a custom error" do
      expect { password.pwned? }.to raise_error(Pwned::Error)
      expect { password.pwned_count }.to raise_error(Pwned::Error)
      expect(@stub).to have_been_requested.times(2)
    end
  end

  describe "when the API returns a 404" do
    # It shouldn't return a 404, but this tests it anyway.
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_return(status: 404)
    end

    it "raises a custom error" do
      expect { password.pwned? }.to raise_error(Pwned::Error)
      expect { password.pwned_count }.to raise_error(Pwned::Error)
      expect(@stub).to have_been_requested.times(2)
    end
  end
end