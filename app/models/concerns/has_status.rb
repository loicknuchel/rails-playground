require "domain/status"

module HasStatus
  extend ActiveSupport::Concern
  included do
    attribute :status, :status
    validates :status, presence: true, inclusion: {in: Status.all}
    # enum status: Status.to_hash, _prefix: true # `TypeError: can't quote Status` no conversions (class<->db)

    scope :status, ->(status) { where status: status }
    Status.all.map { |status| define_method("status_#{status.value}?") { self.status == status } }

    def self.public_count
      status(Status::PUBLIC).count
    end
  end
end
