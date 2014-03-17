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
      # Issue.visible_condition(user, options={}) is used in cross-issues requests
      # (either per-project or cross-project). It determines the ability for a user
      # to access to a list of issues, by generating an SQL fragment that's used
      # later on in requests on the "issues" table.
      #
      # This patch adds a local mask unless the user is admin, in which case he can
      # "see" all issues naturally. The mask are tested against the dedicated
      # column "issues.authorized_viewers" which declares who should see an issue
      # at issue level.
      #
      # See the IssueUserVisibility class in app/services for a detailed description
      # of available masks.
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
        user.projects_by_role.each do |role, projects|
          projects.each do |project|
            conditions << "#{Issue.table_name}.authorized_viewers LIKE '%|role=#{role.id}/project=#{project.id}|%'"
          end
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
