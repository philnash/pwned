RSpec.describe Pwned::Password do
  let(:pwned) { Pwned::Password.new("password") }

  it "initializes with a password" do
    expect(pwned.password).to eq("password")
  end

  it "has a hashed version of the password" do
    expect(pwned.hashed_password).to eq("5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
  end
end