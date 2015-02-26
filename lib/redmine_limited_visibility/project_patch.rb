require_dependency 'project'

class Project

  has_many :project_functions, :dependent => :destroy
  has_many :functions, :through => :project_functions

  has_many :organization_functions

  # Builds a nested hash of users sorted by function and organization
  # => { Function(1) => { Org(1) => [ User(1), User(2), ... ] } }
  #
  # TODO: simplify / refactor / test it correctly !!!
  def users_by_function_and_organization
    dummy_org = Organization.new(:name => l(:label_others))
    self.members.map do |member|
      member.functions.sorted.map do |function|
        { :user => member.user, :function => function, :organization => member.user.organization }
      end
    end.flatten.group_by do |hsh|
      hsh[:function]
    end.inject({}) do |memo, (function, users)|
      if function.hidden_on_overview?
        #do nothing
        memo
      else
        #build a hash for that function
        hsh = users.group_by do |user|
          user[:organization] || dummy_org
        end
        hsh.each do |org, users_hsh|
          hsh[org] = users_hsh.map{|h| h[:user]}.sort
        end
        memo[function] = hsh
        memo
      end
    end
  end

  # Copies members from +project+
  def copy_members(project)

    # Copy users first, then groups to handle members with inherited and given roles
    members_to_copy = []
    members_to_copy += project.memberships.select {|m| m.principal.is_a?(User)}
    members_to_copy += project.memberships.select {|m| !m.principal.is_a?(User)}

    members_to_copy.each do |member|
      new_member = Member.new
      new_member.attributes = member.attributes.dup.except("id", "project_id", "created_on")
      # only copy non inherited roles
      # inherited roles will be added when copying the group membership
      role_ids = member.member_roles.reject(&:inherited?).collect(&:role_id)
      next if role_ids.empty?
      new_member.role_ids = role_ids

      # TODO: Refactor this patch and use alias_method_chain in order to keep untouched the original 'copy_members' method
      # Start
      function_ids = member.member_functions.map(&:function_id)
      new_member.function_ids = function_ids
      # End of the patch

      new_member.project = self
      self.members << new_member
    end

    # Patch - Restart
    self.functions = project.project_functions.map(&:function)

    # TODO Only if organization plugin is installed
    orga_functions_to_copy = project.organization_functions
    orga_functions_to_copy.each do |orga_function|
      new_orga_function = OrganizationFunction.new
      new_orga_function.attributes = orga_function.attributes.dup.except("id", "project_id")
      self.organization_functions << new_orga_function
    end

    orga_roles_to_copy = project.organization_roles
    orga_roles_to_copy.each do |orga_role|
      new_orga_role = OrganizationRole.new
      new_orga_role.attributes = orga_role.attributes.dup.except("id", "project_id")
      self.organization_roles << new_orga_role
      self.organization_roles << new_orga_role
    end
    # End of the patch

  end

end
