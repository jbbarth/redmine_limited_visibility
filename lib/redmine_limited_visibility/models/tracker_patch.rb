require_dependency 'tracker'

module RedmineLimitedVisibility::Models
	module TrackerPatch

	end
end

class Tracker

	prepend RedmineLimitedVisibility::Models::TrackerPatch

	has_many :project_function_trackers, :dependent => :destroy

end
