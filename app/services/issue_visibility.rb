class IssueVisibility
  attr_accessor :user, :issue

  def initialize(user, issue)
    @user = user || User.current
    @issue = issue
  end

  def authorized?
    authorizations = issue.authorized_viewers
    true
  end
end
