require "domain/role"

module HasRole
  extend ActiveSupport::Concern
  included do
    attribute :role, :role
    validates :role, presence: true, inclusion: {in: Role.all}

    scope :role, ->(role) { where role: role }
    Role.all.map { |role| define_method("role_#{role.name}?") { self.role == role } }

    def admin?
      any_role?([Role::ADMIN])
    end

    def author?
      any_role?([Role::ADMIN, Role::AUTHOR])
    end

    def guest?
      any_role?([Role::ADMIN, Role::AUTHOR, Role::GUEST])
    end

    def any_role?(roles)
      roles.any? { |role| self.role == role }
    end
  end
end
