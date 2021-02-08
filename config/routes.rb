RedmineApp::Application.routes.draw do
  resources :functions, except: [:index, :show] do
    collection do
      match '/visibilities', to: "functions#visibilities", :via => [:get, :post]
      put '/available_functions_per_project', to: "functions#available_functions_per_project"
      put '/visible_functions_per_tracker', to: "functions#visible_functions_per_tracker"
      put '/activated_functions_per_tracker', to: "functions#activated_functions_per_tracker"
      put '/copy_functions_settings_from_project', to: "functions#copy_functions_settings_from_project"
    end
  end
  resources :functional_roles, only: [:update]
  get 'issues/functions(/:project_id/:tracker_id)', :controller => 'functions', :action => 'index' ,:as => 'project_functions_index'
end
