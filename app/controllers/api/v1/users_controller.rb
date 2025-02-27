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