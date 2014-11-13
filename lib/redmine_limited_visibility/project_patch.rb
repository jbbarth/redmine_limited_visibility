require_dependency 'project'

class Project

  # Builds a nested hash of users sorted by function and organization
  # => { Function(1) => { Org(1) => [ User(1), User(2), ... ] } }
  #
  # TODO: simplify / refactor / test it correctly !!!
  def users_by_function_and_organization
    dummy_org = Organization.new(:name => l(:label_others))
    self.members.map do |member|
      member.functions.sorted.map do |function|
        { :user => member.user, :function => function, :organization => member.user.organization }
      end
    end.flatten.group_by do |hsh|
      hsh[:function]
    end.inject({}) do |memo, (function, users)|
      if function.hidden_on_overview?
        #do nothing
        memo
      else
        #build a hash for that function
        hsh = users.group_by do |user|
          user[:organization] || dummy_org
        end
        hsh.each do |org, users_hsh|
          hsh[org] = users_hsh.map{|h| h[:user]}.sort
        end
        memo[function] = hsh
        memo
      end
    end
  end
end
