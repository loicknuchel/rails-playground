class Comment < ApplicationRecord
  include HasStatus

  belongs_to :article
end
