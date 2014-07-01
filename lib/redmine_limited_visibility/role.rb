require_dependency 'role'

class Role < ActiveRecord::Base
  after_create :set_own_visibility

  scope :permission_roles, where("limit_visibility = ? OR limit_visibility IS NULL", false)
  scope :visibility_roles, where(limit_visibility: true)

  # Find all roles that can be used to limit the visibility of issues
  def self.find_all_visibility_roles
    Role.where(limit_visibility: true).givable.all
  end

  def self.find_all_permission_roles
    Role.where("limit_visibility = ? OR limit_visibility IS NULL", false).givable.all
  end

  private

    def set_own_visibility
      reload
      if !authorized_viewers.present? || !authorized_viewers.split('|').include?(self.id)
        update_attribute(:authorized_viewers, "#{authorized_viewers.present? ? authorized_viewers : "|"}#{self.id}|")
      end
    end
end
