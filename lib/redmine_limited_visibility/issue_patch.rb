require_dependency 'issue'

module RedmineLimitedVisibility
  module IssuePatch
    def self.included(base)
      base.class_eval do
        unloadable

        safe_attributes "authorized_viewers"

        alias_method :all_notified_users, :notified_users

        # Returns the users that should be notified
        def notified_users
          if involved_roles_ids.present?
            all_notified_users & involved_users
          else
            all_notified_users
          end
        end

        def involved_users
          users = []
          members = Member.joins(:member_roles).where("#{Member.table_name}.project_id = ? AND #{MemberRole.table_name}.role_id IN (?)", project_id, involved_roles_ids)
          members.each do |m|
            users << m.user
          end
          return users
        end

        def involved_roles_ids
          authorized_viewers.split('|').delete_if(&:blank?)
        end

      end
    end
  end
end

unless Issue.included_modules.include? RedmineLimitedVisibility::IssuePatch
  Issue.send :include, RedmineLimitedVisibility::IssuePatch
end
