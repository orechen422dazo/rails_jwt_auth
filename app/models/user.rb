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