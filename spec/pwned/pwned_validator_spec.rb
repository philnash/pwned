RSpec.describe PwnedValidator do
  class Model
    include ActiveModel::Validations

    attr_accessor :password
  end

  describe "when pwned", pwned_range: "5BAA6" do
    it "marks the model as invalid" do
      class ModelWithValidation < Model
        validates :password, pwned: true
      end

      model = ModelWithValidation.new
      model.password = "password"

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq('has previously appeared in a data breach and should not be used')
    end

    it "allows to change the error message" do
      class ModelWithValidationAndCustomMessage < Model
        validates :password, pwned: { message: "has been pwned %{count} times" }
      end
      model = ModelWithValidationAndCustomMessage.new
      model.password = "password"

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq('has been pwned 3303003 times')
    end
  end

  describe "when not pwned", pwned_range: "37D5B" do
    it "reports the model as valid" do
      class ModelWithValidation < Model
        validates :password, pwned: true
      end

      model = ModelWithValidation.new
      model.password = "t3hb3stpa55w0rd"

      expect(model).to be_valid
    end
  end

  describe "when the API times out" do
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_timeout
    end

    it "marks the model as valid when not error handling configured" do
      class ModelWithValidationNoErrorHandling < Model
        validates :password, pwned: true
      end

      model = ModelWithValidationNoErrorHandling.new
      model.password = "password"

      expect(model).to be_valid
    end

    it "raises a custom error when error handling configured to :raise_error" do
      class ModelWithValidationRaiseOnError < Model
        validates :password, pwned: { on_error: :raise_error }
      end

      model = ModelWithValidationRaiseOnError.new
      model.password = "password"

      expect { model.valid? }.to raise_error(Pwned::TimeoutError, /execution expired/)
    end

    it "marks the model as invalid when error handling configured to :invalid" do
      class ModelWithValidationInvalidOnError < Model
        validates :password, pwned: { on_error: :invalid }
      end

      model = ModelWithValidationInvalidOnError.new
      model.password = "password"

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq("could not be verified against the past data breaches")
    end

    it "marks the model as invalid with a custom error message when error handling configured to :invalid" do
      class ModelWithValidationInvalidOnErrorWithCustomMessage < Model
        validates :password, pwned: { on_error: :invalid, error_message: "might be pwned" }
      end

      model = ModelWithValidationInvalidOnErrorWithCustomMessage.new
      model.password = "password"

      expect(model).to_not be_valid
      expect(model.errors[:password].size).to eq(1)
      expect(model.errors[:password].first).to eq("might be pwned")
    end

    it "marks the model as valid when error handling configured to :valid" do
      class ModelWithValidationValidOnError < Model
        validates :password, pwned: { on_error: :valid }
      end

      model = ModelWithValidationValidOnError.new
      model.password = "password"

      expect(model).to be_valid
    end
  end
end
