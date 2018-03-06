# Changelog for `Pwned`

## Ongoing

* 2 major updates
  * Refactors exception handling with built in Ruby method. [PR #1](https://github.com/philnash/pwned/pull/1) thanks @kpumuk
  * Passwords must be strings, the initializer will raise a `TypeError` unless `password.is_a? String`. [dbf7697](https://github.com/philnash/pwned/commit/dbf7697e878d87ac74aed1e715cee19b73473369)

## 1.0.0 / 2018-03-06

Initial release. Includes basic features for checking passwords and their count from the Pwned Passwords API. Allows setting of request headers and other options for open-uri.
