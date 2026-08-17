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
      patch :memo
    end
  end

  resources :attempts, only: [:index, :show, :create]

  # 写経モード。貼り付けたコードをその場で写すだけなので保存はしない。
  get  "shakyo", to: "shakyo#new"
  post "shakyo", to: "shakyo#show"

  # 和訳モード。貼り付けたコードを解析して日本語にする。
  get  "translate", to: "translations#new"
  post "translate", to: "translations#show"
end
