class MemberFunction < ActiveRecord::Base
  belongs_to :member
  belongs_to :function

  # after_destroy :remove_member_if_empty
  # after_create :add_function_to_group_users
  # after_create :add_function_to_subprojects
  # after_destroy :remove_inherited_functions

  validates_presence_of :function

  def inherited?
    !inherited_from.nil?
  end

end
