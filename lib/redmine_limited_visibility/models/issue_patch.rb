require_dependency 'issue'

module RedmineLimitedVisibility
  module IssuePatch
    def self.included(base)
      base.class_eval do
        unloadable

        belongs_to :assigned_function, class_name: "Function",
                foreign_key: "assigned_to_function_id"

        safe_attributes "authorized_viewers", "assigned_to_function_id"

        unless instance_methods.include?(:notified_users_with_limited_visibility)
          def notified_users_with_limited_visibility
            if authorized_viewer_ids.present?
              notified_users_without_limited_visibility & involved_users(self.project)
            else
              notified_users_without_limited_visibility
            end
          end
          alias_method_chain :notified_users, :limited_visibility
        end

        def involved_users(project)
          users_involved_by_their_functions = User.joins(:members => :member_functions)
              .where(:members => { :project_id => project.id },
                     :member_functions => { :function_id => authorized_viewer_ids })

          members_without_functions = Member.includes(:user)
              .where(:members => { :project_id => project.id })
              .reject{|m| m.member_functions.present?}
          users_without_functions = members_without_functions.map(&:user).reject(&:blank?)

          users_involved_by_their_functions | users_without_functions
        end

        def authorized_viewer_ids
          "#{authorized_viewers}".split('|').reject(&:blank?).map(&:to_i)
        end
      end
    end
  end
end

unless Issue.included_modules.include? RedmineLimitedVisibility::IssuePatch
  Issue.send :include, RedmineLimitedVisibility::IssuePatch
end
