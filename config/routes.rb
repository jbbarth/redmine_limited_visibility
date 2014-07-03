RedmineApp::Application.routes.draw do
  put :update_visibility_roles_memberships, to: "visibilities#update_visibility_roles", as: "update_visibility_roles"
  put :update_permissions_roles_by_organization, to: "visibilities#update_permissions_roles_by_organization"
  put :update_visibility_roles_by_organization, to: "visibilities#update_visibility_roles_by_organization"
  match 'roles/visibilities/report', to: "roles#visibilities", :via => [:get, :post]
end
