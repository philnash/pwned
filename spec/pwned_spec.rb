RSpec.describe Pwned do
  it "has a version number" do
    expect(Pwned::VERSION).not_to be nil
  end

  describe "#hash_password" do
    it "returns an uppercase hash of the password" do
      expect(Pwned.hash_password("password")).to eq("5BAA61E4C9B93F3F0682250B6CF8331B7EE68FD8")
    end
  end
end
