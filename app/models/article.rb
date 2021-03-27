class Article < ApplicationRecord
  include HasStatus

  validates :title, presence: true
  validates :body, presence: true, length: {minimum: 10}
  attribute :summary, :optional, type: :string

  has_many :comments, dependent: :destroy
end
