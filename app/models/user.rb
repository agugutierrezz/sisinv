class User < ApplicationRecord
  has_secure_password
  has_secure_token :api_token

  has_many :sessions, dependent: :destroy

  # Normalización sin 'normalizes' (evita el error del seed)
  before_validation do
    self.email_address = email_address.to_s.strip.downcase
  end
  
  enum :role, { user: 0, admin: 1 }

  validates :email_address, presence: true, uniqueness: { case_sensitive: false },
                          format: { with: URI::MailTo::EMAIL_REGEXP }
                
  validates :password, length: { minimum: 8 }, if: -> { new_record? || will_save_change_to_password_digest? }
end
