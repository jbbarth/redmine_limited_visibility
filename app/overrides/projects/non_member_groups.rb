if Redmine::Plugin.installed?(:redmine_organizations)
  Deface::Override.new :virtual_path    => 'projects/settings/_non_member_groups',
                       :name            => 'extend-roles-columns',
                       :set_attributes  => 'td#all_roles',
                       :attributes      => {:colspan => '3'}
end
