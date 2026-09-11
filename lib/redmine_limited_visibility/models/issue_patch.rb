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
        safe_attributes "authorized_viewers", :if => lambda { |issue, user|
          issue.new_record? ||
          user.admin? ||
          user.allowed_to?(:change_issues_visibility, issue.project)
        }

        def involved_users(project)
          if project.module_enabled?("limited_visibility")
            # Members involved by their functions
            users_involved_by_their_functions = User.joins(:members => :member_functions)
                                                    .where(:members => { :project_id => project.id },
                                                           :member_functions => { :function_id => authorized_viewer_ids })

            # Members without functions
            members_without_functions = Member.includes(:user, :member_functions)
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

        before_create :set_default_authorized_viewers

        def default_authorized_viewer_ids(user = author)
          if project.autochecked_functions_mode == '2'
            default_authorized_viewer_ids_for_tracker
          else
            default_authorized_viewer_ids_for_user(user)
          end
        end

        def default_authorized_viewer_ids_for_tracker
          tracker_functions = ProjectFunctionTracker.joins(:project_function).where("project_id = ? AND tracker_id = ?", project_id, tracker_id)
          if tracker_functions.present?
            tracker_functions.select { |f| f.checked == true }.map { |c| c.function.id }
          else
            Function.available_functions_for(project).pluck(:id)
          end
        end

        def default_authorized_viewer_ids_for_user(user)
          user_functions = Function.of_user_in_project(user, project).to_a
          return Function.available_functions_for(project).pluck(:id) if user_functions.empty?

          activated_functions = []
          user_functions.each do |function|
            enabled_functions = []
            ProjectFunction.where(project_id: project_id, function_id: function.id).each do |project_function|
              if project_function.authorized_viewer_ids.present?
                enabled_functions |= Function.where(id: project_function.authorized_viewer_ids).sorted.to_a
              end
            end
            activated_functions |= enabled_functions.presence || Function.where(id: function.authorized_viewer_ids).sorted.to_a
          end
          (activated_functions & Function.available_functions_for(project).to_a).map(&:id)
        end

        def set_default_authorized_viewers
          return unless project&.module_enabled?("limited_visibility")
          return if authorized_viewers.present? || copy?

          self.authorized_viewers = "|#{default_authorized_viewer_ids.join('|')}|"
        end
        private :set_default_authorized_viewers
      end
    end
  end
end

unless Issue.included_modules.include? RedmineLimitedVisibility::Models::IssuePatch
  Issue.include RedmineLimitedVisibility::Models::IssuePatch
end
