require_dependency 'member'

class Member < ActiveRecord::Base

  has_many :member_functions, :dependent => :destroy
  has_many :functions, :through => :member_functions

end
