class User < ApplicationRecord
  include HasRole

  validates :name, presence: true
  validates :email, presence: true
  validates :password, presence: true, length: {minimum: 4}
end
