RSpec.describe Pwned::HashedPassword do
  let(:hashed_password) { Pwned::HashedPassword.new(password_hash) }
  let(:password) { "password" }
  let(:password_hash) { Pwned.hash_password(password) }

  it "initializes with a password" do
    expect(hashed_password.hashed_password).to eq("5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
  end

  describe "when given an integer" do
    let(:password_hash) { 123 }

    it "doesn't initialize" do
      expect { hashed_password }.to raise_error(TypeError)
    end
  end

  describe "when given an array" do
    let(:password_hash) { ["hello", "world"] }

    it "doesn't initialize" do
      expect { hashed_password }.to raise_error(TypeError)
    end
  end

  describe "when given a hash" do
    let(:password_hash) { { a: "b", c: "d" } }

    it "doesn't initialize" do
      expect { hashed_password }.to raise_error(TypeError)
    end
  end

  describe "when pwned", pwned_range: "5BAA6" do
    it "reports it is pwned" do
      expect(hashed_password.pwned?).to be true
      expect(@stub).to have_been_requested
    end

    it "reports it has been pwned many times" do
      expect(hashed_password.pwned_count).to eq(3303003)
      expect(@stub).to have_been_requested
    end

    describe "when given a lower case hash" do
      let(:hashed_password) { Pwned::HashedPassword.new(password_hash) }
      let(:password_hash) { Pwned.hash_password(password).downcase }

      it "upcases the hashed password" do
        expect(hashed_password.hashed_password).to eq("5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
      end

      it "reports it is pwned" do
        expect(hashed_password.pwned?).to be true
        expect(@stub).to have_been_requested
      end
    end
  end
end
