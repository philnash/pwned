# Changelog for `Pwned`

## Ongoing [☰](https://github.com/philnash/pwned/compare/v2.4.0...master)

## 2.4.1 (August 29, 2022) [☰](https://github.com/philnash/pwned/compare/v2.4.0...v2.4.1)

- Minor updates

  - Adds French and Dutch translations
  - Adds Rails 7 to the test matrix

## 2.4.0 (February 23, 2022) [☰](https://github.com/philnash/pwned/compare/v2.3.0...v2.4.0)

- Minor updates

  - Adds `default_request_options` to set global defaults for the gem
  - Adds Ruby 3.1 to the test matrix

## 2.3.0 (August 30, 2021) [☰](https://github.com/philnash/pwned/compare/v2.2.0...v2.3.0)

- Minor updates

  - Restores `Net::HTTP` default behaviour to use environment supplied HTTP
    proxy
  - Adds `ignore_env_proxy` to ignore any proxies set in the environment

## 2.2.0 (March 27, 2021) [☰](https://github.com/philnash/pwned/compare/v2.1.0...v2.2.0)

- Minor updates

  - Adds `:proxy` option to `request_options` to directly set a proxy on the
    request. Fixes #21, thanks [dparpyani](https://github.com/dparpyani).

## 2.1.0 (July 8, 2020) [☰](https://github.com/philnash/pwned/compare/v2.0.2...v2.1.0)

- Minor updates

  - Adds `Pwned::HashedPassword` class which is initializd with a SHA1 hash to
    query the API with so that the lookup can be done in the background without
    storing passwords. Fixes #19, thanks [@paprikati](https://github.com/paprikati).

## 2.0.2 (May 20, 2020) [☰](https://github.com/philnash/pwned/compare/v2.0.1...v2.0.2)

- Minor fix

  - It was found to be possible for reading the lines body of a response to
    result in a `nil` which caused trouble with string concatenation. This
    avoids that scenario. Fixes #18, thanks [@flori](https://github.com/flori).

## 2.0.1 (January 14, 2020) [☰](https://github.com/philnash/pwned/compare/v2.0.0...v2.0.1)

- Minor updates

  - Adds double-splat to ActiveModel::Errors#add calls with options to make Ruby 2.7 happy.
  - Detects presence of Net::HTTPClientException in tests to remove deprecation warning.

## 2.0.0 (October 1, 2019) [☰](https://github.com/philnash/pwned/compare/v1.2.1...v2.0.0)

- Major updates

  - Switches from `open-uri` to `Net::HTTP`. This is a potentially breaking change.
  - `request_options` are now used to configure `Net::HTTP.start`.
  - Rather than using all string keys from `request_options`, HTTP headers are now
    specified in their own `headers` hash. To upgrade, any options intended as
    headers need to be extracted into a `headers` hash, e.g.

    ```diff
      validates :password, not_pwned: {
    -    request_options: { read_timeout: 5, open_timeout: 1, "User-Agent" => "Super fun user agent" }
    +    request_options: { read_timeout: 5, open_timeout: 1, headers: { "User-Agent" => "Super fun user agent" } }
      }

    -  password = Pwned::Password.new("password", 'User-Agent' => 'Super fun new user agent')
    +  password = Pwned::Password.new("password", headers: { 'User-Agent' => 'Super fun new user agent' }, read_timeout: 10)
    ```

  - Adds a CLI to let you check passwords on the command line

    ```bash
    $ pwned password
    Pwned!
    The password has been found in public breaches 3730471 times.
    ```

## 1.2.1 (March 17, 2018) [☰](https://github.com/philnash/pwned/compare/v1.2.0...v1.2.1)

- Minor updates
  - Validator no longer raises `TypeError` when password is `nil`

## 1.2.0 (March 15, 2018) [☰](https://github.com/philnash/pwned/compare/v1.1.0...v1.2.0)

- Major updates
  - Changes `PwnedValidator` to `NotPwnedValidator`, so that the validation looks like `validates :password, not_pwned: true`. `PwnedValidator` now subclasses `NotPwnedValidator` for backwards compatibility with version 1.1.0 but is deprecated.

## 1.1.0 (March 12, 2018) [☰](https://github.com/philnash/pwned/compare/v1.0.0...v1.1.0)

- Major updates

  - Refactors exception handling with built in Ruby method ([PR #1](https://github.com/philnash/pwned/pull/1) thanks [@kpumuk](https://github.com/kpumuk))
  - Passwords must be strings, the initializer will raise a `TypeError` unless `password.is_a? String`. ([dbf7697](https://github.com/philnash/pwned/commit/dbf7697e878d87ac74aed1e715cee19b73473369))
  - Added Ruby on Rails validator ([PR #3](https://github.com/philnash/pwned/pull/3) & [PR #6](https://github.com/philnash/pwned/pull/6))
  - Added simplified accessors `Pwned.pwned?` and `Pwned.pwned_count` ([PR #4](https://github.com/philnash/pwned/pull/4))

- Minor updates
  - SHA1 is only calculated once
  - Frozen string literal to make sure Ruby does not copy strings over and over again
  - Removal of `@match_data`, since we only use it to retrieve the counter. Caching the counter instead (all [PR #2](https://github.com/philnash/pwned/pull/2) thanks [@kpumuk](https://github.com/kpumuk))

## 1.0.0 (March 6, 2018) [☰](https://github.com/philnash/pwned/commits/v1.0.0)

Initial release. Includes basic features for checking passwords and their count from the Pwned Passwords API. Allows setting of request headers and other options for open-uri.
