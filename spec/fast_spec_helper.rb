ENV['RAILS_ENV'] ||= 'test'

# test gems
require 'rspec/rails'
require 'rspec/autorun'
require 'rspec/mocks'
require 'rspec/mocks/standalone'
require 'pry'

# load paths
$:.<< File.expand_path('../../app/models', __FILE__)
$:.<< File.expand_path('../../lib', __FILE__)

require File.expand_path('../factory_girl_helper', __FILE__)

# rspec base config
RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.include ApplicationHelper
  config.include ERB::Util
  config.fixture_path = "#{::Rails.root}/test/fixtures"
  config.use_transactional_fixtures = true
  config.include FactoryGirlHelper
end
