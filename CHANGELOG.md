# Changelog for `Pwned`

## Ongoing [☰](https://github.com/philnash/pwned/compare/v2.0.2...master)

## 2.0.2 (May 20, 2020) [☰](https://github.com/philnash/pwned/compare/v2.0.1...v2.0.2)

- Minor fix

  - It was found to be possible for reading the lines body of a response to
    result in a `nil` which caused trouble with string concatenation. This
    avoids that scenario. Fixes #18, thanks [@flori](https://github.com/flori).

## 2.0.1 (January 14, 2019) [☰](https://github.com/philnash/pwned/compare/v2.0.0...v2.0.1)

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
