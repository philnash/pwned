source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in pwned.gemspec
gemspec

# Allows to switch Rails version in the build matrix
gem "activemodel", ENV["RAILS_VERSION"] ? "~> #{ENV["RAILS_VERSION"]}" : nil
