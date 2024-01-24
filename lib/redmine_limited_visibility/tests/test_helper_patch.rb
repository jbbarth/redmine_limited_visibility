module RedmineLimitedVisibility::Tests::TestHelperPatch
  # Verifies that the query filters match the expected filters
  def assert_query_filters(expected_filters)
    expected_filters << ["authorized_viewers", "mine", [""]]
    super(expected_filters)
  end
end

module Redmine
  class ControllerTest < ActionController::TestCase
    prepend RedmineLimitedVisibility::Tests::TestHelperPatch
  end
end
