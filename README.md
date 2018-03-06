# Pwned

An easy, Ruby way to use the Pwned Passwords API.

[![Build Status](https://travis-ci.org/philnash/pwned.svg?branch=master)](https://travis-ci.org/philnash/pwned)

Troy Hunt's [Pwned Passwords API V2](https://haveibeenpwned.com/API/v2#PwnedPasswords) allows you to check if a password has been found in any of the huge data breaches.

`Pwned` is a Ruby library to use the Pwned Passwords API's [k-Anonymity model](https://www.troyhunt.com/ive-just-launched-pwned-passwords-version-2/#cloudflareprivacyandkanonymity) to test a password against the API without sending the entire password to the service.

The data from this API is provided by [Have I been pwned?](https://haveibeenpwned.com/). Before using the API, please check [the acceptable uses and license of the API](https://haveibeenpwned.com/API/v2#AcceptableUse).

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

### Advanced

You can set options and headers to be used with `open-uri` when making the request to the API. HTTP headers must be string keys and the [other options are available in the `OpenURI::OpenRead` module](https://ruby-doc.org/stdlib-2.5.0/libdoc/open-uri/rdoc/OpenURI/OpenRead.html#method-i-open).

```ruby
password = Pwned::Password.new("password", { 'User-Agent' => 'Super fun new user agent' })
```

### ActiveRecord Validator

There is a custom validator available for your ActiveRecord models:

```ruby
class User < ApplicationRecord
  validates :password, pwned: true
  # or
  validates :password, pwned: { message: "has been pwned %{count} times" }
end
```

You can change the error message using I18n (use `%{count}` to interpolate the number of times the password was seen in the data breaches):

```yaml
en:
  errors:
    messages:
      pwned: has been pwned %{count} times
```

## TODO

- [ ] Devise plugin

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/philnash/pwned. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Pwned project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/philnash/pwned/blob/master/CODE_OF_CONDUCT.md).
