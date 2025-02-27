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