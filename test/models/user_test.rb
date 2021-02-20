require 'test_helper'

class UserTest < ActiveSupport::TestCase
  admin_user = User.new(role: 'admin')

  test 'role? check user role' do
    assert_equal true, admin_user.role?('admin')
    assert_equal false, admin_user.role?('guest')
    assert_raise { admin_user.role?('bad') }
  end

  test 'any_role? check if user has one of the roles' do
    assert_equal true, admin_user.any_role?(%w[admin author])
    assert_equal false, admin_user.any_role?(%w[author guest])
    assert_raise { admin_user.role?(%w[admin bad]) }
  end

  test 'admin?' do
    assert_equal true, User.new(role: 'admin').admin?
    assert_equal false, User.new(role: 'author').admin?
    assert_equal false, User.new(role: 'guest').admin?
  end

  test 'author?' do
    assert_equal true, User.new(role: 'admin').author?
    assert_equal true, User.new(role: 'author').author?
    assert_equal false, User.new(role: 'guest').author?
  end

  test 'guest?' do
    assert_equal true, User.new(role: 'admin').guest?
    assert_equal true, User.new(role: 'author').guest?
    assert_equal true, User.new(role: 'guest').guest?
  end
end
