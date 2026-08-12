Rails.application.routes.draw do
  root "home#index"

  get "signup", to: "users#new"
  post "signup", to: "users#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  resource :user, only: [:edit, :update]

  resources :categories, only: [:index, :show]

  resources :snippets do
    member do
      get :practice
    end
  end

  resources :attempts, only: [:index, :show, :create]
end
