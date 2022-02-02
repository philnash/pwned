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
        if Object.const_defined?("Net::HTTPClientException")
          # Net::HTTPServerException is deprecated in favour of
          # Net::HTTPClientException. More detail here:
          # https://bugs.ruby-lang.org/issues/14688
          expect(error.cause).to be_kind_of(Net::HTTPClientException)
        else
          expect(error.cause).to be_kind_of(Net::HTTPServerException)
        end
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

    it "allows the user agent to be set in constructor" do
      Pwned.default_request_options = { headers: { "User-Agent" => "Default user agent" } }
      password = Pwned::Password.new("password", headers: { "User-Agent" => "Super fun user agent" })
      password.pwned?

      expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").
        with(headers: { "User-Agent" => "Super fun user agent" })).
        to have_been_made.once
    end

    it "allows the user agent to be set with default settings" do
      Pwned.default_request_options = { headers: { "User-Agent" => "Default user agent" } }
      password = Pwned::Password.new("password")
      password.pwned?

      expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6").
        with(headers: { "User-Agent" => "Default user agent" })).
        to have_been_made.once
    end

    let(:subject) { Pwned::Password.new("password", request_options).pwned? }

    let(:request_options) { {} }
    let(:environment_proxy) { "https://username:password@environment.com:12345" }
    let(:explicit_proxy) { "https://username:password@explicit.com:56789" }

    shared_examples_for "uses explicit proxy" do
      it "uses proxy from request options" do
        expect(Net::HTTP).to receive(:start).and_wrap_original do |original_method, *args, &block|
          http = original_method.call(*args)
          expect(http.proxy_from_env?).to eq(false)
          expect(http.proxy_address).to eq("explicit.com")
          expect(http.proxy_user).to eq("username")
          expect(http.proxy_pass).to eq("password")
          expect(http.proxy_port).to eq(56_789)
          original_method.call(*args, &block)
        end

        subject

        expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6")
          .with(headers: { "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" }))
          .to have_been_made.once
      end
    end

    shared_examples_for "doesn't use proxy from environment" do
      context "explicit proxy is given" do
        before { request_options[:proxy] = explicit_proxy }
        include_examples "uses explicit proxy"
      end

      context "explicit proxy not given" do
        before { request_options.delete(:proxy) }

        it "doesn't use a proxy" do
          expect(Net::HTTP).to receive(:start).and_wrap_original do |original_method, *args, &block|
            http = original_method.call(*args)
            expect(http.proxy?).to eq(false)
            original_method.call(*args, &block)
          end

          subject

          expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6")
            .with(headers: { "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" }))
            .to have_been_made.once
        end
      end
    end

    shared_examples_for "uses proxy from environment" do
      context "proxy not given in request options" do
        let(:request_options) { {} }

        it "uses proxy from the environment" do
          expect(Net::HTTP).to receive(:start).and_wrap_original do |original_method, *args, &block|
            http = original_method.call(*args)
            expect(http.proxy_from_env?).to eq(true)
            expect(http.proxy_address).to eq("environment.com")
            expect(http.proxy_user).to eq("username")
            expect(http.proxy_pass).to eq("password")
            expect(http.proxy_port).to eq(12_345)
            original_method.call(*args, &block)
          end

          subject

          expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6")
            .with(headers: { "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" }))
            .to have_been_made.once
        end
      end
    end

    context "proxy exists in environment" do
      before { ENV["http_proxy"] = environment_proxy }

      context "ignore_env_proxy is not given" do
        before { request_options.delete(:ignore_env_proxy) }

        context "proxy is given in request options" do
          before { request_options[:proxy] = explicit_proxy }
          include_examples "uses explicit proxy"
        end

        include_examples "uses proxy from environment"
      end

      context "ignore_env_proxy is false" do
        before { request_options[:ignore_env_proxy] = false }

        context "proxy is given in request options" do
          before { request_options[:proxy] = explicit_proxy }
          include_examples "uses explicit proxy"
        end

        include_examples "uses proxy from environment"
      end

      context "ignore_env_proxy is true" do
        before { request_options[:ignore_env_proxy] = true }

        include_examples "doesn't use proxy from environment"
      end
    end

    context "proxy environment variable does not exist" do
      before { ENV["http_proxy"] = nil }

      context "ignore_env_proxy is not given" do
        before { request_options.delete(:ignore_env_proxy) }
        include_examples "doesn't use proxy from environment"
      end

      context "ignore_env_proxy is true" do
        before { request_options[:ignore_env_proxy] = true }
        include_examples "doesn't use proxy from environment"
      end

      context "ignore_env_proxy is false" do
        before { request_options[:ignore_env_proxy] = false }
        include_examples "doesn't use proxy from environment"
      end
    end

    context "proxy given in default request options" do
      before { Pwned.default_request_options = { proxy: "https://username:password@default.com:12345" } }

      it "uses proxy from the default require options" do
        expect(Net::HTTP).to receive(:start).and_wrap_original do |original_method, *args, &block|
          http = original_method.call(*args)
          expect(http.proxy_from_env?).to eq(false)
          expect(http.proxy_address).to eq("default.com")
          expect(http.proxy_user).to eq("username")
          expect(http.proxy_pass).to eq("password")
          expect(http.proxy_port).to eq(12_345)
          original_method.call(*args, &block)
        end

        subject

        expect(a_request(:get, "https://api.pwnedpasswords.com/range/5BAA6")
          .with(headers: { "User-Agent" => "Ruby Pwned::Password #{Pwned::VERSION}" }))
          .to have_been_made.once
      end
    end
  end

  describe "streaming", pwned_range: "A0F41" do
    let(:password) { Pwned::Password.new("fake-password") }

    # Since our streaming is yielding by line across chunks, ensure we're not
    # missing lines by checking a single line file
    it "streams the whole file" do
      expect(password).to be_pwned
    end

    it "works when response stream returns several empty chunks" do
      response = double
      allow(response).to receive(:read_body).
        and_yield("").
        and_yield("").
        and_yield("hello\nworld\n")

      password.send(:stream_response_lines, response) do |line|
        expect(line).to eq("hello\n") | eq("world\n")
      end
    end
  end

  describe "empty response", pwned_range: "AD871" do
    let(:password) { Pwned::Password.new("empty") }

    it "is not pwned" do
      expect(password).not_to be_pwned
    end
  end
end
