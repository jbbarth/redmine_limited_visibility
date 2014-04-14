class IssueUserVisibility
  attr_accessor :user, :issue

  def initialize(user, issue)
    @user = user
    @issue = issue
  end

  def user
    @user ||= default_user
  end

  # This method looks at the "authorized_viewers" field on the issue (but it could
  # be any other type of object, really), and determines if the user can see this
  # object :
  #
  #   authorized_viewers = nil
  #   authorized_viewers = ""
  #   authorized_viewers = "*"
  #   => ANYONE can see
  #
  #   authorized_viewers = "||"
  #   => NOBODY can see
  #
  #   authorized_viewers = "|user=23|
  #   => ONLY User(23) can see
  #
  #   authorized_viewers = "|user=23|gorup=34|
  #   => ONLY User(23) and Group(34) can see
  #
  #   authorized_viewers = "|user=23|user=34|organization=52|
  #   => ONLY User(23), User(34) and Organization(52) can see
  #
  #   authorized_viewers = "|role=4/project=27|"
  #   => ONLY users with Role(4) on Project(27) can see
  #
  def authorized?
    authorizations = issue.authorized_viewers.to_s
    # dummy cases, core tests, and existing tickets
    return true if authorizations == "" || authorizations == "*"
    # always return true if user is an admin
    return true if user.admin?
    # else we tokenize with "|" to get authorizations
    authorizations_tokens = authorizations.split("|").reject{ |t| t == "" }
    #... we build an array of current users tokens
    current_user_tokens = ["user=#{user.id}"]
    current_user_tokens += user.group_ids.map{ |gid| "group=#{gid}" }
    current_user_tokens << "organization=#{user.organization_id}" if user.respond_to?(:organization_id)
    current_user_tokens += role_ids.map{ |rid| "role=#{rid}/project=#{issue.project_id}" }
    #... and see if something matches
    (authorizations_tokens & current_user_tokens).any?
  end

  private
  def default_user
    User.current
  end

  def role_ids
    user.roles_for_project(issue.project).map(&:id)
  end
end
