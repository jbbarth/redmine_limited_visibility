require_dependency 'issue'

module RedmineLimitedVisibility
  module PrependedIssuePatch
    def notified_users
      if authorized_viewer_ids.present?
        super & involved_users(self.project)
      else
        super
      end
    end
  end
end
Issue.prepend RedmineLimitedVisibility::PrependedIssuePatch

module RedmineLimitedVisibility
  module IssuePatch

    def self.included(base)
      base.class_eval do
        unloadable

        belongs_to :assigned_function, class_name: "Function",
                foreign_key: "assigned_to_function_id"

        safe_attributes "authorized_viewers", "assigned_to_function_id"

        def involved_users(project)
          if project.module_enabled?("limited_visibility")
            users_involved_by_their_functions = User.joins(:members => :member_functions)
                                                    .where(:members => { :project_id => project.id },
                                                           :member_functions => { :function_id => authorized_viewer_ids })

            members_without_functions = Member.includes(:user)
                                            .where(:members => { :project_id => project.id })
                                            .reject{|m| m.member_functions.present?}
            users_without_functions = members_without_functions.map(&:user).reject(&:blank?)

            users_involved_by_their_functions | users_without_functions
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

unless Issue.included_modules.include? RedmineLimitedVisibility::IssuePatch
  Issue.include RedmineLimitedVisibility::IssuePatch
end
