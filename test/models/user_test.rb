require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "retrieves fixtures" do
    users = User.all
    assert_equal 3, users.length
    admin_user = users.find { |u| u.name == "admin" }
    author_user = users.find { |u| u.name == "author" }
    guest_user = users.find { |u| u.name == "guest" }

    assert_equal users(:admin), admin_user
    assert_equal "admin", admin_user.name
    assert_equal "admin@mail.com", admin_user.email
    assert_equal "admin", admin_user.password
    assert_equal Role::ADMIN, admin_user.role
    assert admin_user.admin?
    assert admin_user.author?
    assert admin_user.guest?

    assert_equal users(:author), author_user
    assert_equal "author", author_user.name
    assert_equal "author@mail.com", author_user.email
    assert_equal "author", author_user.password
    assert_equal Role::AUTHOR, author_user.role
    assert_not author_user.admin?
    assert author_user.author?
    assert author_user.guest?

    assert_equal users(:guest), guest_user
    assert_equal "guest", guest_user.name
    assert_equal "guest@mail.com", guest_user.email
    assert_equal "guest", guest_user.password
    assert_equal Role::GUEST, guest_user.role
    assert_not guest_user.admin?
    assert_not guest_user.author?
    assert guest_user.guest?
  end
  test "validates correctness" do
    User.create!(name: "loic", email: "loic@mail.com", password: "loic", role: Role::ADMIN)
    assert_raise(ActiveRecord::RecordInvalid) { User.create!(name: "", email: "loic@mail.com", password: "loic", role: Role::ADMIN) }
    assert_raise(ActiveRecord::RecordInvalid) { User.create!(name: "loic", email: "", password: "loic", role: Role::ADMIN) }
    assert_raise(ActiveRecord::RecordInvalid) { User.create!(name: "loic", email: "loic@mail.com", password: "abc", role: Role::ADMIN) }
    assert_raise(ActiveRecord::RecordInvalid) { User.create!(name: "loic", email: "loic@mail.com", password: "", role: Role::ADMIN) }
    assert_raise(ArgumentError) { User.create!(name: "loic", email: "loic@mail.com", password: "", role: "bad") }
    assert_raise(ArgumentError) { User.create!(name: "loic", email: "loic@mail.com", password: "", role: "") }
  end
  test "persists and retrieves User" do
    user = User.create!(name: "loic", email: "loic@mail.com", password: "loic", role: Role::ADMIN)
    assert_equal user, User.find_by_name("loic")
    assert_equal user, User.find_by_email("loic@mail.com")
  end

  test "admin?" do
    assert_equal true, User.new(role: Role::ADMIN).admin?
    assert_equal false, User.new(role: Role::AUTHOR).admin?
    assert_equal false, User.new(role: Role::GUEST).admin?
  end
  test "author?" do
    assert_equal true, User.new(role: Role::ADMIN).author?
    assert_equal true, User.new(role: Role::AUTHOR).author?
    assert_equal false, User.new(role: Role::GUEST).author?
  end
  test "guest?" do
    assert_equal true, User.new(role: Role::ADMIN).guest?
    assert_equal true, User.new(role: Role::AUTHOR).guest?
    assert_equal true, User.new(role: Role::GUEST).guest?
  end
end
