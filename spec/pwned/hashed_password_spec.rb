RSpec.describe Pwned::HashedPassword do
  subject(:hashed_password) { Pwned::HashedPassword.new(password_hash) }

  let(:password) { "password" }
  let(:password_hash) { Pwned.hash_password(password) }

  it "initializes with a password" do
    expect(hashed_password.hashed_password).to eq("5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
  end

  context "when given an integer" do
    let(:password_hash) { 123 }

    it "doesn't initialize" do
      expect { hashed_password }.to raise_error(TypeError)
    end
  end

  context "when given an array" do
    let(:password_hash) { ["hello", "world"] }

    it "doesn't initialize" do
      expect { hashed_password }.to raise_error(TypeError)
    end
  end

  context "when given a hash" do
    let(:password_hash) { { a: "b", c: "d" } }

    it "doesn't initialize" do
      expect { hashed_password }.to raise_error(TypeError)
    end
  end
end
