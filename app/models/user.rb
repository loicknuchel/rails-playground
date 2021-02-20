class User < ApplicationRecord
  enum role: { admin: 0, author: 1, guest: 2 } # https://naturaily.com/blog/ruby-on-rails-enum

  def role?(role)
    raise "'#{role}' does not exist in User::roles" unless User.roles.key?(role)

    role == self.role
  end

  def any_role?(roles)
    roles.any? { |role| role?(role) }
  end

  def admin?
    role?('admin')
  end

  def author?
    any_role?(%w[admin author])
  end

  def guest?
    any_role?(%w[admin author guest])
  end
end
