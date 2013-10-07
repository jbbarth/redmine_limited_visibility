ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../../../../config/environment', __FILE__)
require File.expand_path('../fast_spec_helper', __FILE__)

#fixtures!
require 'rspec/rails'
RSpec.configure do |config|
  config.fixture_path = File.expand_path('../../../../test/fixtures', __FILE__)
end
