group :development, :test do
  # Pin minitest to avoid compatibility issues with Rails 7.2.2.2
  # Rails 8+ should be compatible with minitest 6.x
  gem 'minitest', '~> 5.0', '< 6.0' if Rails::VERSION::MAJOR < 8
end
