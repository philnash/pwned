class Model
  include ActiveModel::Validations

  attr_accessor :password
end

def create_model(password)
  Model.new.tap { |model| model.password = password }
end

RSpec.describe NotPwnedValidator do
  after(:example) do
    Model.clear_validators!
  end

  describe "when pwned", pwned_range: "5BAA6" do
    it "marks the model as invalid" do
      Model.validates :password, not_pwned: true
      model = create_model("password")

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq("has previously appeared in a data breach and should not be used")
    end

    it "allows to change the error message" do
      Model.validates :password, not_pwned: { message: "has been pwned %{count} times" }
      model = create_model("password")

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq("has been pwned 3303003 times")
    end

    it "allows the user agent to be set" do
      # Default option should be overridden
      Pwned.default_request_options = { headers: { "User-Agent" => "Default user agent" } }

      Model.validates :password, not_pwned: {
        request_options: { headers: { "User-Agent" => "Super fun user agent" } }
      }
      model = create_model("password")

      expect(model).to_not be_valid
      expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").
        with(headers: { "User-Agent" => "Super fun user agent" })).
        to have_been_made.once
    end

    it "allows the proxy to be set via options" do
      # Default option should be overridden
      Pwned.default_request_options = { proxy: "https://username:password@default.com:12345" }

      Model.validates :password, not_pwned: {
        request_options: { proxy: "https://username:password@example.com:12345" }
      }
      model = create_model("password")

      # Webmock doesn't support proxy assertions (https://github.com/bblimke/webmock/issues/753)
      # so we check that Net::HTTP receives the correct arguments.
      expect(Net::HTTP).to receive(:start).
        with("api.pwnedpasswords.com", 443, "example.com", 12345, "username", "password", anything).
        and_call_original

      expect(model).to_not be_valid
      expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").
        with(headers: { "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" })).
        to have_been_made.once
    end

    it "allows the proxy to be set via default options" do
      Pwned.default_request_options = { proxy: "https://username:password@default.com:12345" }
      Model.validates :password, not_pwned: true
      model = create_model("password")

      # Webmock doesn't support proxy assertions (https://github.com/bblimke/webmock/issues/753)
      # so we check that Net::HTTP receives the correct arguments.
      expect(Net::HTTP).to receive(:start).
        with("api.pwnedpasswords.com", 443, "default.com", 12345, "username", "password", anything).
        and_call_original

      expect(model).to_not be_valid
      expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").
        with(headers: { "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" })).
        to have_been_made.once
    end
  end

  describe "when not pwned", pwned_range: "37D5B" do
    it "reports the model as valid" do
      Model.validates :password, not_pwned: true
      model = create_model("t3hb3stpa55w0rd")

      expect(model).to be_valid
    end
  end

  describe "with a threshold for pwned count", pwned_range: "613D1" do
    it "reports the model as invalid when pwned count is above threshold" do
      Model.validates :password, not_pwned: { threshold: 1 }
      model = create_model("harlequin10")

      expect(model).to_not be_valid
    end

    it "reports the model as valid when pwned count is below threshold" do
      Model.validates :password, not_pwned: { threshold: 10 }
      model = create_model("harlequin10")

      expect(model).to be_valid
    end

    it "expects threshold to be an integer" do
      Model.validates :password, not_pwned: { threshold: "10" }
      model = create_model("harlequin10")

      expect { model.valid? }.to raise_error(TypeError, /NotPwnedValidator option 'threshold'/)
    end
  end

  describe "when the API times out" do
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_timeout
    end

    it "marks the model as valid when not error handling configured" do
      Model.validates :password, not_pwned: true
      model = create_model("password")

      expect(model).to be_valid
    end

    it "raises a custom error when error handling configured to :raise_error" do
      Model.validates :password, not_pwned: { on_error: :raise_error }
      model = create_model("password")

      expect { model.valid? }.to raise_error(Pwned::TimeoutError, /execution expired/)
    end

    it "marks the model as invalid when error handling configured to :invalid" do
      Model.validates :password, not_pwned: { on_error: :invalid }
      model = create_model("password")

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq("could not be verified against the past data breaches")
    end

    it "marks the model as invalid with a custom error message when error handling configured to :invalid" do
      Model.validates :password, not_pwned: { on_error: :invalid, error_message: "might be pwned" }
      model = create_model("password")

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq("might be pwned")
    end

    it "marks the model as valid when error handling configured to :valid" do
      Model.validates :password, not_pwned: { on_error: :valid }
      model = create_model("password")

      expect(model).to be_valid
    end

    it "calls a proc configured for error handling" do
      Model.validates :password, not_pwned: { on_error: ->(record, error) { raise RuntimeError, "custom proc" } }
      model = create_model("password")

      expect { model.valid? }.to raise_error(RuntimeError, "custom proc")
    end
  end

  describe "when the model's password is not present" do
    it "is valid with a `nil` password" do
      Model.validates :password, not_pwned: true
      model = Model.new
      expect(model).to be_valid
    end

    it "is valid with a `blank` password" do
      Model.validates :password, not_pwned: true
      model = Model.new
      model.password = ""
      expect(model).to be_valid
    end
  end
end

# Supports the 1.1.0 `pwned: true` validation. Should be removed eventually.
RSpec.describe PwnedValidator do
  after(:example) do
    Model.clear_validators!
  end

  describe "when pwned", pwned_range: "5BAA6" do
    it "marks the model as invalid" do
      Model.validates :password, pwned: true
      model = create_model("password")

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq("has previously appeared in a data breach and should not be used")
    end
  end

  describe "when not pwned", pwned_range: "37D5B" do
    it "reports the model as valid" do
      Model.validates :password, pwned: true
      model = create_model("t3hb3stpa55w0rd")

      expect(model).to be_valid
    end
  end
end
