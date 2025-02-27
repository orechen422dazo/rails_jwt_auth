# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # サインアップ
      post "signup", to: "users#create"

      # サインイン
      post "signin", to: "sessions#create"

      # 認証が必要なAPI
      resources :protected_resource, only: [:index], constraints: lambda { |req| req.format == :json }
    end
  end
end