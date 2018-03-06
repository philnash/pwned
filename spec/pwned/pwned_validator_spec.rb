RSpec.describe PwnedValidator do
  let(:file_5BAA6) { File.new('./spec/fixtures/5BAA6.txt') }

  class Model
    include ActiveModel::Validations

    attr_accessor :password
  end

  describe "when pwned" do
    before(:example) do
      @stub = stub_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").to_return(body: file_5BAA6)
    end

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
end
