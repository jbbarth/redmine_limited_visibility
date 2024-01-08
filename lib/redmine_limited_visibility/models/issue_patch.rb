require_dependency 'issue'

module RedmineLimitedVisibility::Models
  module PrependedIssuePatch
    def notified_users
      if authorized_viewer_ids.present?
        owners = [author, assigned_to, previous_assignee].compact.uniq
        super & (involved_users(self.project) | owners)
      else
        super
      end
    end
  end
end
Issue.prepend RedmineLimitedVisibility::Models::PrependedIssuePatch

module RedmineLimitedVisibility::Models
  module IssuePatch

    include Redmine::SafeAttributes

    def self.included(base)
      base.class_eval do

        belongs_to :assigned_function, class_name: "Function",
                   foreign_key: "assigned_to_function_id"

        safe_attributes "assigned_to_function_id"
        safe_attributes "authorized_viewers" #, :if => lambda { |issue, user| user.admin? || user.allowed_to?(:change_issues_visibility, issue.project) } TODO Complete this check: users may also set visibility when they have no permissions (using a issue-template for instance)

        def involved_users(project)
          if project.module_enabled?("limited_visibility")
            # Members involved by their functions
            users_involved_by_their_functions = User.joins(:members => :member_functions)
                                                    .where(:members => { :project_id => project.id },
                                                           :member_functions => { :function_id => authorized_viewer_ids })

            # Members without functions
            members_without_functions = Member.includes(:user)
                                              .where(:members => { :project_id => project.id })
                                              .reject { |m| m.member_functions.present? }
            users_without_functions = members_without_functions.map(&:user).reject(&:blank?)

            if Redmine::Plugin.installed?(:redmine_organizations)
              # NonMembers in an Organization which has an exception for this project
              organization_non_members_with_authorization = Organization.joins(:organization_non_member_functions)
                                                                        .where("organization_non_member_functions.function_id IN (?)", authorized_viewer_ids)
                                                                        .where("organization_non_member_functions.project_id = ?", project.id)
                                                                        .uniq.map(&:self_and_descendants).flatten
              users_non_members_but_authorized = User.where(organization: organization_non_members_with_authorization)
            end

            users_involved_by_their_functions | users_without_functions | users_non_members_but_authorized.to_a
          else
            all_members = User.joins(:members).where(:members => { :project_id => project.id })
            all_members
          end
        end

        def authorized_viewer_ids
          "#{authorized_viewers}".split('|').reject(&:blank?).map(&:to_i)
        end
      end
    end
  end
end

unless Issue.included_modules.include? RedmineLimitedVisibility::Models::IssuePatch
  Issue.include RedmineLimitedVisibility::Models::IssuePatch
end
