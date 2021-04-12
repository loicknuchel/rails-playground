Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "articles#index"

  resources :users
  resources :articles do
    resources :comments
  end

  post "/tracking", to: "analytics#create"

  mount Auth::Engine => "/", :as => "auth"
end
