ENV["RAILS_ENV"] ||= 'test'
require File.expand_path('../../../../config/environment', __FILE__)
require File.expand_path('../fast_spec_helper', __FILE__)

#fixtures!
require 'rspec/rails'
RSpec.configure do |config|
  #if we cannot configure fixtures, it's probably because they are already configured
  #in an other spec_helper in an other plugin...
  if config.respond_to?(:fixture_path=)
    config.fixture_path = File.expand_path('../../../../test/fixtures', __FILE__)
  end
end
