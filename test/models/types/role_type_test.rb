require "test_helper"
require "domain/role"
require "types/role_type"

class RoleTypeTest < ActiveSupport::TestCase
  type = RoleType.new

  test "cast" do
    assert_equal Role::ADMIN, type.cast(Role::ADMIN)
    assert_equal Role::AUTHOR, type.cast(Role::AUTHOR)
    assert_equal Role::GUEST, type.cast(Role::GUEST)
    assert_equal Role::ADMIN, type.cast("admin")
    assert_equal Role::AUTHOR, type.cast("author")
    assert_equal Role::GUEST, type.cast("guest")
    assert_equal Role::ADMIN, type.cast(0)
    assert_equal Role::AUTHOR, type.cast(1)
    assert_equal Role::GUEST, type.cast(2)
    assert_nil type.cast(nil)
    assert_raise(ArgumentError) { type.cast("bad") }
    assert_raise(ArgumentError) { type.cast(12) }
  end
  test "serialize" do
    assert_equal 0, type.serialize(Role::ADMIN)
    assert_equal 1, type.serialize(Role::AUTHOR)
    assert_equal 2, type.serialize(Role::GUEST)
    assert_nil type.serialize(nil)
    assert_raise(ArgumentError) { type.serialize("bad") }
  end
end
