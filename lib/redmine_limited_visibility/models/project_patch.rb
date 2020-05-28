require_dependency 'project'

class Project

  has_many :project_functions, :dependent => :destroy
  has_many :functions, :through => :project_functions
  has_many :project_function_trackers, :through => :project_functions

  has_many :organization_functions if Redmine::Plugin.installed?(:redmine_organizations)

  if Redmine::Plugin.installed?(:redmine_organizations)
    # Builds a nested hash of users sorted by function and organization
    # => { Function(1) => { Org(1) => [ User(1), User(2), ... ] } }
    #
    # TODO: simplify / refactor / test it correctly !!!
    def users_by_function_and_organization
      dummy_org = Organization.new(:name => l(:label_others))
      self.members.map do |member|
        member.functions.sorted.map do |function|
          {:user => member.user, :function => function, :organization => member.user.organization}
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
            hsh[org] = users_hsh.map {|h| h[:user]}.sort
          end
          memo[function] = hsh
          memo
        end
      end
    end
  end

  # Builds a nested hash of functions sorted by user
  def functions_per_user
    # TODO: Use cache strategy instead
    return @functions_per_user if @functions_per_user
    @functions_per_user = {}
    self.members.map do |member|
      @functions_per_user[member.user_id] = member.functions.map(&:id)
    end
    @functions_per_user
  end

  def members_per_function
    hash = {}
    self.members.includes(:member_functions).each do |m|
      m.member_functions.each do |f|
        hash[f.function_id] = 0 if hash[f.function_id].blank?
        hash[f.function_id] += 1
      end
    end
    hash
  end

  # Returns a hash of project users grouped by function
  def users_by_function
    members.includes(:user, :functions).inject({}) do |h, m|
      m.functions.each do |r|
        h[r] ||= []
        h[r] << m.user
      end
      h
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

      ### TODO: Refactor this patch and use Module#prepend in order to keep untouched the original 'copy_members' method
      ### Start
      function_ids = member.member_functions.map(&:function_id)
      new_member.function_ids = function_ids
      ### End of the patch

      new_member.project = self
      self.members << new_member
    end

    ### Patch - Restart
    self.functions = project.project_functions.map(&:function)

    # Only if organization plugin is installed
    if Redmine::Plugin.installed?(:redmine_organizations)
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
      end
    end
    ### End of the patch

  end

end
