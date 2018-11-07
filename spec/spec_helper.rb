ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../../../config/environment', __FILE__)
require File.expand_path("../../../redmine_base_rspec/spec/spec_helper", __FILE__)
require File.expand_path('../../../../test/object_helpers', __FILE__)
include ObjectHelpers
