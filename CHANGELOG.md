# Changelog for `Pwned`

## Ongoing [☰](https://github.com/philnash/pwned/compare/v1.0.0...master)

* Major updates
  * Refactors exception handling with built in Ruby method ([PR #1](https://github.com/philnash/pwned/pull/1) thanks [@kpumuk](https://github.com/kpumuk))
  * Passwords must be strings, the initializer will raise a `TypeError` unless `password.is_a? String`. ([dbf7697](https://github.com/philnash/pwned/commit/dbf7697e878d87ac74aed1e715cee19b73473369))
  * Added Ruby on Rails validator ([PR #3](https://github.com/philnash/pwned/pull/3))

* Minor updates
  * SHA1 is only calculated once
  * Frozen string literal to make sure Ruby does not copy strings over and over again
  * Removal of `@match_data`, since we only use it to retrieve the counter. Caching the counter instead (all [PR #2](https://github.com/philnash/pwned/pull/2) thanks [@kpumuk](https://github.com/kpumuk))

## 1.0.0 (March 6, 2018) [☰](https://github.com/philnash/pwned/commits/v1.0.0)

Initial release. Includes basic features for checking passwords and their count from the Pwned Passwords API. Allows setting of request headers and other options for open-uri.
