require_dependency 'role'

class Role < ActiveRecord::Base
  after_create :set_own_visibility

  scope :visibility_roles, where(limit_visibility: true)  # Find all roles used to limit the visibility of issues
  scope :permission_roles, where("limit_visibility = ? OR limit_visibility IS NULL", false)

  private
    def set_own_visibility
      reload
      if !authorized_viewers.present? || !authorized_viewers.split('|').include?(self.id)
        update_attribute(:authorized_viewers, "#{authorized_viewers.present? ? authorized_viewers : "|"}#{self.id}|")
      end
    end
end
