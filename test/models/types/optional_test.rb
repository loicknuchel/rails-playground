require "test_helper"

class OptionalTest < ActiveSupport::TestCase
  str_opt = Optional.new({type: :string})
  str_opt_with_blank = Optional.new({type: :string, allow_blank: true})
  int_opt = Optional.new({type: :integer})

  test "fail with bad arguments" do
    assert_raise(ArgumentError) { Optional.new }
    assert_raise(ArgumentError) { Optional.new({}) }
    assert_raise(ArgumentError) { Optional.new({type: :bad}) }
    assert_raise(ArgumentError) { Optional.new({type: :string, bad: 1}) }
  end
  test "cast" do
    assert_equal Some("a"), str_opt.cast("a")
    assert_equal None(), str_opt.cast(" ")
    assert_equal None(), str_opt.cast("")
    assert_equal None(), str_opt.cast(nil)
    assert_equal Some("1"), str_opt.cast(1)

    assert_equal Some("a"), str_opt_with_blank.cast("a")
    assert_equal Some(" "), str_opt_with_blank.cast(" ")
    assert_equal Some(""), str_opt_with_blank.cast("")
    assert_equal None(), str_opt_with_blank.cast(nil)

    assert_equal Some(1), int_opt.cast(1)
    assert_equal Some(1), int_opt.cast("1")
    assert_equal Some(0), int_opt.cast("a")
    assert_equal None(), int_opt.cast(nil)
  end
  test "serialize" do
    assert_equal "a", str_opt.serialize(Some("a"))
    assert_nil str_opt.serialize(Some(" "))
    assert_nil str_opt.serialize(Some(""))
    assert_nil str_opt.serialize(None())

    assert_equal "a", str_opt_with_blank.serialize(Some("a"))
    assert_equal " ", str_opt_with_blank.serialize(Some(" "))
    assert_equal "", str_opt_with_blank.serialize(Some(""))
    assert_nil str_opt_with_blank.serialize(None())

    assert_equal 1, int_opt.serialize(Some(1))
    assert_equal 1, int_opt.serialize(Some("1"))
    assert_nil int_opt.serialize(Some("a"))
    assert_nil int_opt.serialize(None())
  end
end
