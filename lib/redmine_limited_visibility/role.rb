require_dependency 'role'

class Role < ActiveRecord::Base

  # Find all the roles that can be used to limit the visibility of issues
  def self.find_all_visibility_roles
    Role.where(:limit_visibility => true).givable.all
  end

end
