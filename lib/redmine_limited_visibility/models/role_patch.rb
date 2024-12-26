require_dependency 'role'

module RedmineLimitedVisibility::Models
  module RolePatch

  end
end

class Role

  prepend RedmineLimitedVisibility::Models::RolePatch

  has_and_belongs_to_many :managed_functions, :class_name => 'Function',
                          :join_table => "#{table_name_prefix}roles_managed_functions#{table_name_suffix}",
                          :association_foreign_key => "managed_function_id"

  safe_attributes 'functions_managed',
                  'all_functions_managed',
                  "all_organizations_managed",
                  'managed_function_ids',
                  'hidden_on_overview'

end
