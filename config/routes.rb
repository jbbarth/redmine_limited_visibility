RedmineApp::Application.routes.draw do
  resources :functions, except: [:index, :show] do
    collection do
      match '/visibilities', to: "functions#visibilities", :via => [:get, :post]
      put '/available_functions_per_project', to: "functions#available_functions_per_project"
      put '/visible_functions_per_tracker', to: "functions#visible_functions_per_tracker"
    end
  end
  resources :functional_roles, only: [:update]
end
