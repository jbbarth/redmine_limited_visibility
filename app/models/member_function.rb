class MemberFunction < ApplicationRecord
  belongs_to :member
  belongs_to :function

  after_create :add_function_to_subprojects
  after_destroy :remove_inherited_functions

  validates_presence_of :function

  def inherited?
    !inherited_from.nil?
  end

  # Returns the MemberFunction from which self was inherited, or nil
  def inherited_from_member_function
    MemberFunction.find_by_id(inherited_from) if inherited_from
  end

  private

  def add_function_to_subprojects
    member.project.children.each do |subproject|
      if subproject.inherit_members?
        child_member = Member.find_or_initialize_by(project: subproject, user_id: member.user_id)
        if child_member.roles.any? # only add the function if the user is already a member of the subproject
          child_member.member_functions << MemberFunction.new(:function => function, :inherited_from => id)
          child_member.save!
        end
      end
    end
  end

  def remove_inherited_functions
    MemberFunction.where(:inherited_from => id).destroy_all
  end

end
