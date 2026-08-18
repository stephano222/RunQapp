Rails.application.routes.draw do
  root "home#index"

  # 死活監視用。外部サービスから定期的に叩いてスリープを防ぐ用途にも使う。
  get "health", to: "health#show"

  get "signup", to: "users#new"
  post "signup", to: "users#create"
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  # 何も入力せずお試し用アカウントで入るための入り口
  post "guest_login", to: "sessions#guest"
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

  # 管理者だけが見られる利用状況の画面
  namespace :admin do
    resource :dashboard, only: [:show]
  end
end
