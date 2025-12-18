group :development, :test do
  # Pin minitest for Redmine 6 (Rails 7). Redmine 7 (Rails 8) is compatible with minitest >= 6
  gem 'minitest', '~> 5.0', '< 6.0' if File.read('lib/redmine/version.rb') =~ /MAJOR\s*=\s*(\d+)/ && $1.to_i < 7
end
