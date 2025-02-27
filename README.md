# Rails JWT Auth

## 1. ユーザーモデル

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
  
  # JWTトークン用にユーザー情報をペイロードに変換
  def to_token_payload
    {
      sub: id,
      email: email
    }
  end
end
```

## 2. APIコントローラーの基底クラス

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  
  # 認証用のヘルパーメソッド
  def current_user
    @current_user ||= authenticate_token
  end

  def logged_in?
    !!current_user
  end

  def authenticate_user!
    render json: { error: '認証が必要です' }, status: :unauthorized unless logged_in?
  end

  private

  def authenticate_token
    authenticate_with_http_token do |token, options|
      begin
        decoded = JWT.decode(token, Rails.application.credentials.secret_key_base, true, { algorithm: 'HS256' })
        User.find(decoded[0]["sub"])
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        nil
      end
    end
  end
end
```

## 3. API用のユーザーコントローラー（サインアップ）

```ruby
# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < ApplicationController
      # POST /api/v1/signup
      def create
        @user = User.new(user_params)
        
        if @user.save
          token = generate_token(@user)
          render json: { 
            user: { id: @user.id, email: @user.email }, 
            token: token 
          }, status: :created
        else
          render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:email, :password, :password_confirmation)
      end
      
      def generate_token(user)
        payload = user.to_token_payload
        JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
      end
    end
  end
end
```

## 4. API用のセッションコントローラー（サインイン/サインアウト）

```ruby
# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < ApplicationController
      # POST /api/v1/signin
      def create
        user = User.find_by(email: params[:email])
        
        if user && user.authenticate(params[:password])
          token = generate_token(user)
          render json: { 
            user: { id: user.id, email: user.email }, 
            token: token 
          }
        else
          render json: { error: "メールアドレスまたはパスワードが無効です" }, status: :unauthorized
        end
      end

      # トークンベースの認証ではサーバーサイドでのログアウト処理は不要
      # クライアントがトークンを破棄すれば良い
      # 必要に応じてトークンのブラックリスト化などを実装可能

      private
      
      def generate_token(user)
        payload = user.to_token_payload
        JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
      end
    end
  end
end
```

## 5. API用のルーティング

```ruby
# config/routes.rb
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # サインアップ
      post 'signup', to: 'users#create'
      
      # サインイン
      post 'signin', to: 'sessions#create'
      
      # 認証が必要なAPI
      resources :protected_resource, only: [:index], constraints: lambda { |req| req.format == :json }
    end
  end
end
```

## 6. 認証済みAPIリソースの例

```ruby
# app/controllers/api/v1/protected_resource_controller.rb
module Api
  module V1
    class ProtectedResourceController < ApplicationController
      before_action :authenticate_user!
      
      # GET /api/v1/protected_resource
      def index
        render json: { 
          message: "認証済みAPIにアクセスしました", 
          user: { id: current_user.id, email: current_user.email } 
        }
      end
    end
  end
end
```

## 7. JWTのGemを追加

JWTを使用するために、Gemfileに以下を追加する必要があります：
```ruby
# # Gemfileに以下を追加
gem "jwt"
gem "rack-cors"
gem "bcrypt"
```

# JWTとCORSのGem追加後に実行
```shell
bundle install
```

## 8. CORS設定

API用にCORS設定を追加：

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'  # 本番環境では特定のオリジンに制限することを推奨

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization']
  end
end
```

## 必要なコマンド（API モード）
APIモードの新規アプリケーション作成（既存アプリケーションの場合はスキップ）

```shell
rails new rails_jwt_auth --api
```

### ユーザーモデルの作成
```shell
rails generate model User email:string password_digest:string
```

### API用のコントローラーディレクトリとファイルの作成
```shell
rails generate controller api/v1/Users create
rails generate controller api/v1/Sessions create
rails generate controller api/v1/ProtectedResource index
```

### マイグレーションの実行
```shell
rails db:migrate
```

## API リクエスト例
curlコマンドを使用してAPIリクエストを送信する例：

サインアップ（ユーザー登録）:
```shell
curl -X POST http://localhost:3000/api/v1/signup \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test@example.com", "password": "password123", "password_confirmation": "password123"}}'
```

サインイン（ログイン）:
```shell
curl -X POST http://localhost:3000/api/v1/signin \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "password123"}'
```