require_dependency 'issue'

module RedmineLimitedVisibility
  module IssuePatch
    def self.included(base)
      base.class_eval do
        unloadable

        safe_attributes "authorized_viewers"

        unless instance_methods.include?(:notified_users_with_limited_visibility)
          def notified_users_with_limited_visibility
            if authorized_viewer_ids.present?
              notified_users_without_limited_visibility & involved_users
            else
              notified_users_without_limited_visibility
            end
          end
          alias_method_chain :notified_users, :limited_visibility
        end

        def involved_users
          members = Member.joins(:member_roles).where("#{Member.table_name}.project_id = ? AND #{MemberRole.table_name}.role_id IN (?)", project_id, authorized_viewer_ids)
          members.map(&:user)
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
