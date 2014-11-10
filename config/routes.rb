RedmineApp::Application.routes.draw do
  resources :functions, except: [:index, :show] do
    collection do
      match '/visibilities', to: "functions#visibilities", :via => [:get, :post]
    end
  end
  resources :functional_roles, only: [:update]
end
