# Pwned

An easy, Ruby way to use the Pwned Passwords API.

[![Gem Version](https://badge.fury.io/rb/pwned.svg)](https://rubygems.org/gems/pwned) ![Build Status](https://github.com/philnash/pwned/workflows/tests/badge.svg) [![Maintainability](https://codeclimate.com/github/philnash/pwned/badges/gpa.svg)](https://codeclimate.com/github/philnash/pwned/maintainability) [![Inline docs](https://inch-ci.org/github/philnash/pwned.svg?branch=master)](https://inch-ci.org/github/philnash/pwned)

[API docs](https://www.rubydoc.info/gems/pwned) | [GitHub repo](https://github.com/philnash/pwned)

## Table of Contents

* [Table of Contents](#table-of-contents)
* [About](#about)
* [Installation](#installation)
* [Usage](#usage)
  * [Plain Ruby](#plain-ruby)
    * [Custom request options](#custom-request-options)
      * [HTTP Headers](#http-headers)
      * [HTTP Proxy](#http-proxy)
  * [ActiveRecord Validator](#activerecord-validator)
    * [I18n](#i18n)
    * [Threshold](#threshold)
    * [Network Error Handling](#network-error-handling)
    * [Custom Request Options](#custom-request-options-1)
      * [HTTP Headers](#http-headers-1)
      * [HTTP Proxy](#http-proxy-1)
  * [Using Asynchronously](#using-asynchronously)
  * [Devise](#devise)
  * [Rodauth](#rodauth)
  * [Command line](#command-line)
  * [Unpwn](#unpwn)
* [How Pwned is Pi?](#how-pwned-is-pi)
* [Development](#development)
* [Contributing](#contributing)
* [License](#license)
* [Code of Conduct](#code-of-conduct)

## About

Troy Hunt's [Pwned Passwords API](https://haveibeenpwned.com/API/v3#PwnedPasswords) allows you to check if a password has been found in any of the huge data breaches.

`Pwned` is a Ruby library to use the Pwned Passwords API's [k-Anonymity model](https://www.troyhunt.com/ive-just-launched-pwned-passwords-version-2/#cloudflareprivacyandkanonymity) to test a password against the API without sending the entire password to the service.

The data from this API is provided by [Have I been pwned?](https://haveibeenpwned.com/). Before using the API, please check [the acceptable uses and license of the API](https://haveibeenpwned.com/API/v3#AcceptableUse).

Here is a blog post I wrote on [how to use this gem in your Ruby applications to make your users' passwords better](https://www.twilio.com/blog/2018/03/better-passwords-in-ruby-applications-pwned-passwords-api.html).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pwned'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pwned

## Usage

There are a few ways you can use this gem:

1. [Plain Ruby](#plain-ruby)
2. [Rails](#activerecord-validator)
3. [Rails and Devise](#devise)

### Plain Ruby

To test a password against the API, instantiate a `Pwned::Password` object and then ask if it is `pwned?`.

```ruby
password = Pwned::Password.new("password")
password.pwned?
#=> true
password.pwned_count
#=> 3303003
```

You can also check how many times the password appears in the dataset.

```ruby
password = Pwned::Password.new("password")
password.pwned_count
#=> 3303003
```

Since you are likely using this as part of a signup flow, it is recommended that you rescue errors so if the service does go down, your user journey is not disturbed.

```ruby
begin
  password = Pwned::Password.new("password")
  password.pwned?
rescue Pwned::Error => e
  # Ummm... don't worry about it, I guess?
end
```

Most of the times you only care if the password has been pwned before or not. You can use simplified accessors to check whether the password has been pwned, or how many times it was pwned:

```ruby
Pwned.pwned?("password")
#=> true
Pwned.pwned_count("password")
#=> 3303003
```

#### Custom request options

You can set HTTP request options to be used with `Net::HTTP.start` when making the request to the API. These options are documented in the [`Net::HTTP.start` documentation](https://ruby-doc.org/stdlib-3.0.0/libdoc/net/http/rdoc/Net/HTTP.html#method-c-start).

You can pass the options to the constructor:

```ruby
password = Pwned::Password.new("password", read_timeout: 10)
```

You can also specify global defaults:

```ruby
Pwned.default_request_options = { read_timeout: 10 }
```

##### HTTP Headers

The `:headers` option defines defines HTTP headers. These headers must be string keys.

```ruby
password = Pwned::Password.new("password", headers: {
  'User-Agent' => 'Super fun new user agent'
})
```

##### HTTP Proxy

An HTTP proxy can be set using the `http_proxy` or `HTTP_PROXY` environment variable. This is the same way that `Net::HTTP` handles HTTP proxies if no proxy options are given. See [`URI::Generic#find_proxy`](https://ruby-doc.org/stdlib-3.0.1/libdoc/uri/rdoc/URI/Generic.html#method-i-find_proxy) for full details on how Ruby detects a proxy from the environment.

```ruby
# Set in the environment
ENV["http_proxy"] = "https://username:password@example.com:12345"

# Will use the above proxy
password = Pwned::Password.new("password")
```

You can specify a custom HTTP proxy with the `:proxy` option:

```ruby
password = Pwned::Password.new(
  "password",
  proxy: "https://username:password@example.com:12345"
)
```

If you don't want to set a proxy and you don't want a proxy to be inferred from the environment, set the `:ignore_env_proxy` key:

```ruby
password = Pwned::Password.new("password", ignore_env_proxy: true)
```

### ActiveRecord Validator

There is a custom validator available for your ActiveRecord models:

```ruby
class User < ApplicationRecord
  validates :password, not_pwned: true
  # or
  validates :password, not_pwned: { message: "has been pwned %{count} times" }
end
```

#### I18n

You can change the error message using I18n (use `%{count}` to interpolate the number of times the password was seen in the data breaches):

```yaml
en:
  errors:
    messages:
      not_pwned: has been pwned %{count} times
      pwned_error: might be pwned
```

#### Threshold

If you are ok with the password appearing a certain number of times before you decide it is invalid, you can set a threshold. The validator will check whether the `pwned_count` is greater than the threshold.

```ruby
class User < ApplicationRecord
  # The record is marked as valid if the password has been used once in the breached data
  validates :password, not_pwned: { threshold: 1 }
end
```

#### Network Error Handling

By default the record will be treated as valid when we cannot reach the [haveibeenpwned.com](https://haveibeenpwned.com/) servers. This can be changed with the `:on_error` validator parameter:

```ruby
class User < ApplicationRecord
  # The record is marked as valid on network errors.
  validates :password, not_pwned: true
  validates :password, not_pwned: { on_error: :valid }

  # The record is marked as invalid on network errors
  # (error message "could not be verified against the past data breaches".)
  validates :password, not_pwned: { on_error: :invalid }

  # The record is marked as invalid on network errors with custom error.
  validates :password, not_pwned: { on_error: :invalid, error_message: "might be pwned" }

  # We will raise an error on network errors.
  # This means that `record.valid?` will raise `Pwned::Error`.
  # Not recommended to use in production.
  validates :password, not_pwned: { on_error: :raise_error }

  # Call custom proc on error. For example, capture errors in Sentry,
  # but do not mark the record as invalid.
  validates :password, not_pwned: {
    on_error: ->(record, error) { Raven.capture_exception(error) }
  }
end
```

#### Custom Request Options

You can configure network requests made from the validator using `:request_options` (see [Net::HTTP.start](http://ruby-doc.org/stdlib-2.6.3/libdoc/net/http/rdoc/Net/HTTP.html#method-c-start) for the list of available options).

```ruby
  validates :password, not_pwned: {
    request_options: {
      read_timeout: 5,
      open_timeout: 1
    }
  }
```

These options override the globally defined default options (see above).

In addition to these options, you can also set the following:

##### HTTP Headers

HTTP headers can be specified with the `:headers` key (e.g. `"User-Agent"`)

```ruby
  validates :password, not_pwned: {
    request_options: {
      headers: { "User-Agent" => "Super fun user agent" }
    }
  }
```

##### HTTP Proxy

An HTTP proxy can be set using the `http_proxy` or `HTTP_PROXY` environment variable. This is the same way that `Net::HTTP` handles HTTP proxies if no proxy options are given. See [`URI::Generic#find_proxy`](https://ruby-doc.org/stdlib-3.0.1/libdoc/uri/rdoc/URI/Generic.html#method-i-find_proxy) for full details on how Ruby detects a proxy from the environment.

```ruby
  # Set in the environment
  ENV["http_proxy"] = "https://username:password@example.com:12345"

  validates :password, not_pwned: true
```

You can specify a custom HTTP proxy with the `:proxy` key:

```ruby
  validates :password, not_pwned: {
    request_options: {
      proxy: "https://username:password@example.com:12345"
    }
  }
```

If you don't want to set a proxy and you don't want a proxy to be inferred from the environment, set the `:ignore_env_proxy` key:

```ruby
  validates :password, not_pwned: {
    request_options: {
      ignore_env_proxy: true
    }
  }
```

### Using Asynchronously

You may have a use case for hashing the password in advance, and then making the call to the Pwned Passwords API later (for example if you want to enqueue a job without storing the plaintext password). To do this, you can hash the password with the `Pwned.hash_password` method and then initialize the `Pwned::HashedPassword` class with the hash, like this:

```ruby
hashed_password = Pwned.hash_password(password)
# some time later
Pwned::HashedPassword.new(hashed_password, request_options).pwned?
```

The `Pwned::HashedPassword` constructor takes all the same options as the regular `Pwned::Password` contructor.

### Devise

If you are using [Devise](https://github.com/heartcombo/devise) I recommend you use the [devise-pwned_password extension](https://github.com/michaelbanfield/devise-pwned_password) which is now powered by this gem.

### Rodauth

If you are using [Rodauth](https://github.com/jeremyevans/rodauth) then you can use the [rodauth-pwned](https://github.com/janko/rodauth-pwned) feature which is powered by this gem.

### Command line

The gem provides a command line utility for checking passwords. You can call it from your terminal application like this:

```bash
$ pwned password
Pwned!
The password has been found in public breaches 3645804 times.
```

If you don't want the password you are checking to be visible, call:

```bash
$ pwned --secret
```

You will be prompted for the password, but it won't be displayed.

### Unpwn

To cut down on unnecessary network requests, [the unpwn project](https://github.com/indirect/unpwn) uses a list of the top one million passwords to check passwords against. Only if a password is not included in the top million is it then checked against the Pwned Passwords API.

## How Pwned is Pi?

[@daz](https://github.com/daz) [shared](https://twitter.com/dazonic/status/1074647842046660609) a fantastic example of using this gem to show how many times the digits of Pi have been used as passwords and leaked.

```ruby
require 'pwned'

PI = '3.14159265358979323846264338327950288419716939937510582097494459230781640628620899862803482534211706798214808651328230664709384460955058223172535940812848111'

for n in 1..40
  password = Pwned::Password.new PI[0..(n + 1)]
  str = [ n.to_s.rjust(2) ]
  str << (password.pwned? ? '😡' : '😃')
  str << password.pwned_count.to_s.rjust(4)
  str << password.password

  puts str.join ' '
end
```

The results may, or may not, surprise you.

```
 1 😡   16 3.1
 2 😡  238 3.14
 3 😡   34 3.141
 4 😡 1345 3.1415
 5 😡 2552 3.14159
 6 😡  791 3.141592
 7 😡 9582 3.1415926
 8 😡 1591 3.14159265
 9 😡  637 3.141592653
10 😡  873 3.1415926535
11 😡  137 3.14159265358
12 😡  103 3.141592653589
13 😡   65 3.1415926535897
14 😡  201 3.14159265358979
15 😡   41 3.141592653589793
16 😡   57 3.1415926535897932
17 😡   28 3.14159265358979323
18 😡   29 3.141592653589793238
19 😡    1 3.1415926535897932384
20 😡    7 3.14159265358979323846
21 😡    5 3.141592653589793238462
22 😡    2 3.1415926535897932384626
23 😡    2 3.14159265358979323846264
24 😃    0 3.141592653589793238462643
25 😡    3 3.1415926535897932384626433
26 😃    0 3.14159265358979323846264338
27 😃    0 3.141592653589793238462643383
28 😃    0 3.1415926535897932384626433832
29 😃    0 3.14159265358979323846264338327
30 😃    0 3.141592653589793238462643383279
31 😃    0 3.1415926535897932384626433832795
32 😃    0 3.14159265358979323846264338327950
33 😃    0 3.141592653589793238462643383279502
34 😃    0 3.1415926535897932384626433832795028
35 😃    0 3.14159265358979323846264338327950288
36 😃    0 3.141592653589793238462643383279502884
37 😃    0 3.1415926535897932384626433832795028841
38 😃    0 3.14159265358979323846264338327950288419
39 😃    0 3.141592653589793238462643383279502884197
40 😃    0 3.1415926535897932384626433832795028841971
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/philnash/pwned. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pwned project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/philnash/pwned/blob/master/CODE_OF_CONDUCT.md).
