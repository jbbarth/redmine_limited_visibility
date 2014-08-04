ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../../../config/environment', __FILE__)
require File.expand_path('../fast_spec_helper', __FILE__)
require File.expand_path('../factories/roles', __FILE__)

def populate_membership # TODO delete, create a fixture and improve it
  User.current = User.find(1)
  @role1 = find_or_create(:role, name: "Contractors", limit_visibility: true)
  @role2 = find_or_create(:role, name: "Project Office", limit_visibility: true)
  @orga = Organization.first
  @project = Project.first

  if Redmine::Plugin.installed?(:redmine_organizations)
    @membership = OrganizationMembership.where(organization_id: @orga.id, project_id: @project.id).first
    if @membership == nil
      @membership = OrganizationMembership.create!(organization: @orga, project: @project, roles: [@role1], users: [User.current])
    else
      @membership.users << User.current
    end
  else
    @membership = Member.new(user_id: User.current.id, project_id: @project.id)
  end
  @membership.roles << @role1
  @membership.save!
  User.current.member_of?(@project).should be true
end
