require_dependency 'project'

class Project

  has_many :project_functions, :dependent => :destroy
  has_many :functions, :through => :project_functions, :before_remove => :update_project_function_trackers
  has_many :project_function_trackers, :through => :project_functions
  has_many :organization_non_member_functions, :dependent => :destroy

  has_many :organization_functions, :dependent => :destroy if Redmine::Plugin.installed?(:redmine_organizations)

  after_save :remove_inherited_member_functions, :add_inherited_member_functions,
             :if => Proc.new { |project| project.saved_change_to_parent_id? }

  def update_project_function_trackers(obj)
    id = ProjectFunction.where(function_id: obj.id, project_id: self.id).map(&:id)
    ProjectFunctionTracker.where(project_function_id: id).delete_all
  end

  # Add patches to core method
  def update_inherited_members
    if parent
      if inherit_members? && !inherit_members_before_last_save
        remove_inherited_member_roles
        remove_inherited_member_functions # PATCH
        add_inherited_member_roles
        add_inherited_member_functions # PATCH
      elsif !inherit_members? && inherit_members_before_last_save
        remove_inherited_member_roles
        remove_inherited_member_functions # PATCH
      end
    end
  end

  def remove_inherited_member_functions
    member_functions = MemberFunction.where(:member_id => membership_ids).to_a
    member_function_ids = member_functions.map(&:id)
    member_functions.each do |member_function|
      if member_function.inherited_from && !member_function_ids.include?(member_function.inherited_from)
        member_function.destroy
      end
    end
  end

  def add_inherited_member_functions
    if inherit_members? && parent
      parent.memberships.each do |parent_member|
        member = Member.find_or_initialize_by(project_id: self.id, user_id: parent_member.user_id)
        parent_member.member_functions.each do |parent_member_function|
          member.member_functions << MemberFunction.new(:function => parent_member_function.function, :inherited_from => parent_member_function.id)
        end
        member.save!
      end
      memberships.reset
    end
  end

  if Redmine::Plugin.installed?(:redmine_organizations)
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
          # do nothing
          memo
        else
          # build a hash for that function
          hsh = users.group_by do |user|
            user[:organization] || dummy_org
          end
          hsh.each do |org, users_hsh|
            hsh[org] = users_hsh.map { |h| h[:user] }.sort
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

  # Deletes all project's members
  def delete_all_members
    me, mr = Member.table_name, MemberRole.table_name
    self.class.connection.delete(
      "DELETE FROM #{mr} WHERE #{mr}.member_id IN (SELECT #{me}.id FROM #{me} " \
        "WHERE #{me}.project_id = #{id})"
    )
    # start Patch
    Member.where(:project_id => id).each do |member|
      member.member_functions.delete_all
      member.delete
    end
    # Member.where(:project_id => id).delete_all
    # end Patch
  end

end

module RedmineLimitedVisibility::Models
  module ProjectPatch
    # Copies members from +project+
    def copy_functions_organizations_of_members(project)
      self.members.each do |member|
        m_project_origin = Member.where(user_id: member.user_id, project_id: project.id)
        member.function_ids = m_project_origin[0].member_functions.map(&:function_id)
      end

      # Only if organization plugin is installed
      if Redmine::Plugin.installed?(:redmine_organizations)
        orga_functions_to_copy = project.organization_functions
        orga_functions_to_copy.each do |orga_function|
          new_orga_function = OrganizationFunction.new
          new_orga_function.attributes = orga_function.attributes.dup.except("id", "project_id")
          self.organization_functions << new_orga_function
        end
      end
    end

    def copy_functions(project)
      self.project_functions = []
      project.project_functions.each do |pf|
        new_pf = ProjectFunction.new
        new_pf.attributes = pf.attributes.dup.except("id", "project_id")
        pf.project_function_trackers.each do |pft|
          new_pft = ProjectFunctionTracker.new
          new_pft.attributes = pft.attributes.dup.except("id", "project_function_id")
          new_pf.project_function_trackers << new_pft
        end
        self.project_functions << new_pf
      end
      self.autochecked_functions_mode = project.autochecked_functions_mode
    end

    def copy(project, options = {})
      super
      project = project.is_a?(Project) ? project : Project.find(project)

      to_be_copied = %w(functions functions_organizations_of_members)

      to_be_copied = to_be_copied & Array.wrap(options[:only]) unless options[:only].nil?

      Project.transaction do
        if save
          reload

          to_be_copied.each do |name|
            send "copy_#{name}", project
          end

          save
        else
          false
        end
      end
    end
  end
end

Project.prepend RedmineLimitedVisibility::Models::ProjectPatch
