class User < ApplicationRecord
  has_secure_password

  has_many :snippets, dependent: :nullify
  has_many :attempts, dependent: :destroy

  before_save { self.email = email.downcase }

  validates :name, presence: true, length: { maximum: 30 }
  validates :email, presence: true, uniqueness: true,
                     format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, allow_nil: true
end
