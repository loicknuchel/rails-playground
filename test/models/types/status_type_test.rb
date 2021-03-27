require "test_helper"
require "domain/status"
require "types/status_type"

class StatusTypeTest < ActiveSupport::TestCase
  type = StatusType.new

  test "cast" do
    assert_equal Status::PUBLIC, type.cast("public")
    assert_equal Status::PRIVATE, type.cast("private")
    assert_equal Status::ARCHIVED, type.cast("archived")
    assert_equal Status::PUBLIC, type.cast(Status::PUBLIC)
    assert_equal Status::PRIVATE, type.cast(Status::PRIVATE)
    assert_equal Status::ARCHIVED, type.cast(Status::ARCHIVED)
    assert_nil type.cast(nil)
    assert_raise(ArgumentError) { type.cast("bad") }
  end
  test "serialize" do
    assert_equal "public", type.serialize(Status::PUBLIC)
    assert_equal "private", type.serialize(Status::PRIVATE)
    assert_equal "archived", type.serialize(Status::ARCHIVED)
    assert_nil type.serialize(nil)
    assert_raise(ArgumentError) { type.serialize("bad") }
  end
end
