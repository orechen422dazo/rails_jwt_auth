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