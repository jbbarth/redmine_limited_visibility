require_dependency 'tracker'

class Tracker < ActiveRecord::Base
	has_many :project_function_trackers, :dependent => :destroy
end