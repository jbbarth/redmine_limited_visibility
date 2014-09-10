RedmineApp::Application.routes.draw do
  put :update_visibility_roles_memberships, to: "visibilities#update_visibility_roles", as: "update_visibility_roles"
  match 'roles/visibilities/report', to: "roles#visibilities", :via => [:get, :post]
end
