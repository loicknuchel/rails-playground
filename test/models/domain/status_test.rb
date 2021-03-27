require "test_helper"

class StatusTest < ActiveSupport::TestCase
  test "new is private" do
    assert_raise(NoMethodError) { Status.new("bad") }
  end
  test "find status by value" do
    assert_equal Status::PUBLIC, Status.find!("public")
    assert_equal Status::PRIVATE, Status.find!("private")
    assert_equal Status::ARCHIVED, Status.find!("archived")
    assert_raise(ArgumentError) { Status.find!("bad") }
  end
end
