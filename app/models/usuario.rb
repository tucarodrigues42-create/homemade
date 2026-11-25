class Usuario < ApplicationRecord
  has_secure_password

  before_validation { self.email = email.to_s.strip.downcase }

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6, maximum: 72 }, allow_nil: true

  scope :em_ordem, -> { order(:email) }
end
