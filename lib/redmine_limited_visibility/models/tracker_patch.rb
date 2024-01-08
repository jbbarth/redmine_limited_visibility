require_dependency 'tracker'

module RedmineLimitedVisibility::Models
	module TrackerPatch

	end
end

class Tracker < ActiveRecord::Base

	prepend RedmineLimitedVisibility::Models::TrackerPatch

	has_many :project_function_trackers, :dependent => :destroy

end
