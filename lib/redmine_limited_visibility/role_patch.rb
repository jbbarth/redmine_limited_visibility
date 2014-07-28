require_dependency 'role'

class Role
  # Role.reset_column_information doesn't actually reset the column names
  # which breaks migrations in the core when we have a 'require_dependency
  # "roles"' like above
  #
  # NB: this only happens with the "roles" table it seems, don't know why
  #
  # Be prepared to some yak shaving:
  # - Role.reset_column_information is defined in the ActiveRecord::ModelSchema
  #   concern
  # - the method contains:
  #
  #   connection.schema_cache.clear_table_cache!(table_name) if table_exists?
  #
  # - table_exists? ~ proxies to connection.schema_cache ... which is stale
  #   in a core migration but I don't know why:
  #
  #   Role.table_exists?
  #   => false
  #   Role.connection.schema_cache.table_exists?("roles")
  #   => false
  #   Role.connection.table_exists?("roles")
  #   => true
  #
  # Hence, we need to patch this to actually not hit the schema_cache. So we have
  # two choices:
  # - either patch Role.table_exists?, which is very small and easy to
  #   patch, but might be used in a *lot* of places and result in a performance
  #   impact
  # - either patch Role.reset_column_information, which is large *but* isn't used
  #   in the core nor in rails, so it might be safer
  class << self
    def reset_column_information_with_safe_schema_clear
      connection.schema_cache.clear_table_cache!(table_name) if connection.table_exists?(table_name)
      reset_column_information_without_safe_schema_clear
    end
    alias_method_chain :reset_column_information, :safe_schema_clear
  end

  after_create :set_own_visibility,
    :if => Proc.new { |_| Role.column_names.include?("authorized_viewers") }

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
