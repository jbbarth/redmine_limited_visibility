require_dependency 'issue'
require_relative '../../app/services/issue_user_visibility'

module RedmineLimitedVisibility
  module IssuePatch
    def self.included(base)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)

      base.class_eval do
        unloadable
        alias_method_chain :visible?, :limited_visibility
        safe_attributes "authorized_viewers"

        class << self
          alias_method_chain :visible_condition, :limited_visibility
        end
      end
    end

    module ClassMethods
      def visible_condition_with_limited_visibility(user, options = {})
        base_condition = visible_condition_without_limited_visibility(user, options)
        return base_condition if user.admin?
        conditions = []
        conditions << "#{Issue.table_name}.authorized_viewers IS NULL"
        conditions << "#{Issue.table_name}.authorized_viewers IN ('', '*')"
        conditions << "#{Issue.table_name}.authorized_viewers LIKE '%|user=#{user.id}|%'"
        conditions << "#{Issue.table_name}.authorized_viewers LIKE '%|organization=#{user.organization_id}|%'" if user.respond_to?(:organization_id) && user.organization_id.present?
        user.group_ids.each do |gid|
          conditions << "#{Issue.table_name}.authorized_viewers LIKE '%|group=#{gid}|%'"
        end
        limited_condition = "(#{conditions.join(" OR ")})"
        if base_condition.blank?
          limited_condition
        else
          "(#{base_condition} AND #{limited_condition})"
        end
      end
    end

    module InstanceMethods
      def visible_with_limited_visibility?(user = nil)
        visible_without_limited_visibility?(user) && IssueUserVisibility.new(user, self).authorized?
      end
    end
  end
end

unless Issue.included_modules.include? RedmineLimitedVisibility::IssuePatch
  Issue.send :include, RedmineLimitedVisibility::IssuePatch
end
