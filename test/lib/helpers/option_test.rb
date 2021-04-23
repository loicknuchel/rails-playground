require "test_helper"
require "helpers/option"

class OptionTest < ActiveSupport::TestCase
  some = Option::Some.new("a")
  none = Option::None.instance

  test "option creation" do
    assert_equal some, Option.new("a")
    assert_equal none, Option.new(nil)
    assert_equal none, Option.empty
    assert_equal some, Option.from_nillable_or_option('a')
    assert_equal some, Option.from_nillable_or_option(some)
    assert_equal none, Option.from_nillable_or_option(nil)
    assert_equal none, Option.from_nillable_or_option(none)
    assert_raise(NoMethodError) { Option::AbstractClass.new("a") }
  end
  test "some?" do
    assert_equal true, some.some?
    assert_equal false, none.some?
    assert_equal true, some.present?
    assert_equal false, none.present?
  end
  test "none?" do
    assert_equal false, some.none?
    assert_equal true, none.none?
    assert_equal false, some.blank?
    assert_equal true, none.blank?
  end
  test "get_or_else" do
    assert_equal "a", some.get_or_else("b")
    assert_equal "b", none.get_or_else("b")
    assert_equal "a", some.get_or_else { "b" }
    assert_equal "b", none.get_or_else { "b" }
    assert_raise(ArgumentError) { some.get_or_else("b") { "b" } }
    assert_raise(ArgumentError) { none.get_or_else("b") { "b" } }
  end
  test "get_or_raise" do
    assert_equal "a", some.get_or_raise(ArgumentError)
    assert_raise(Option::NoSuchElementError) { none.get_or_raise }
    assert_raise(ArgumentError) { none.get_or_raise(ArgumentError) }
  end
  test "get_or_nil" do
    assert_equal "a", some.get_or_nil
    assert_nil none.get_or_nil
  end
  test "map" do
    assert_equal Some("A"), some.map { |v| v.upcase }
    assert_equal none, none.map { |v| v.upcase }
    assert_equal none, some.map { |v| nil }
    assert_equal Some(Some("ab")), some.map { |v| Some(v + "b") }
    assert_raise(ArgumentError) { some.map }
  end
  test "flat_map" do
    assert_equal Some("ab"), some.flat_map { |v| Some(v + "b") }
    assert_equal none, some.flat_map { |v| none }
    assert_equal none, none.flat_map { |v| Some("b") }
    assert_equal none, none.flat_map { |v| none }
    assert_equal Some(6), Some(1).flat_map { |a| Some(2).flat_map { |b| Some(3).flat_map { |c| Some(a + b + c) } } }
    assert_equal Some(6), Some(1).flat_map { |a| Some(2).flat_map { |b| Some(3).map { |c| a + b + c } } }
    assert_equal Some(Some("a")), some.flat_map { |v| Some(Some(v)) }
    assert_raise(ArgumentError) { some.flat_map }
  end
  test "fold" do
    # two values
    assert_equal "ok", some.fold("ko", "ok")
    assert_equal "ko", none.fold("ko", "ok")

    # proc on empty
    assert_equal "ok", some.fold(proc { "ko" }, "ok")
    assert_equal "ko", none.fold(proc { "ko" }, "ok")

    # proc on present
    assert_equal "a", some.fold("ko", proc { |v| v.to_s })
    assert_equal "ko", none.fold("ko", proc { |v| v.to_s })

    # block on present
    assert_equal "a", some.fold("ko", &:to_s)
    assert_equal "ko", none.fold("ko", &:to_s)
    assert_equal "ak", some.fold("ko") { |v| v + "k" }
    assert_equal "ko", none.fold("ko") { |v| v + "k" }

    # missing empty case
    assert_raise(ArgumentError) { some.fold }

    # missing present case
    assert_raise(ArgumentError) { some.fold("ko") }

    # present case twice
    assert_raise(ArgumentError) { some.fold("ko", "ok") { |v| v + "k" } }
  end
  test "has?" do
    assert some.has? { |value| value == "a" }
    assert_not some.has? { |value| value != "a" }
    assert_not none.has? { |value| value == "a" }
    assert_not none.has? { |value| value != "a" }
    assert_raise(ArgumentError) { some.has? }
  end
  test "or" do
    # return the first option present of two
    assert_equal some, some.or(Some("b"))
    assert_equal Some("b"), none.or(Some("b"))
    assert_equal some, some.or(none)
    assert_equal none, none.or(none)

    # return the first option present of many
    assert_equal some, some.or(Some("b"), Some("c"), Some("d"))
    assert_equal Some("b"), none.or(Some("b"), Some("c"), Some("d"))
    assert_equal Some("b"), none.or(Some("b"), none, Some("d"))
    assert_equal Some("b"), none.or(Some("b"), none, none)
    assert_equal Some("c"), none.or(none, Some("c"), Some("d"))
    assert_equal Some("d"), none.or(none, none, Some("d"))
    assert_equal none, none.or(none, none, none)

    # handle block also
    assert_equal some, (some.or { Some("b") })
    assert_equal Some("b"), (none.or { Some("b") })
    assert_equal some, (some.or(Some("b"), Some("c")) { Some("d") })
    assert_equal Some("b"), (none.or(Some("b"), Some("c")) { Some("d") })
    assert_equal Some("c"), (none.or(none, Some("c")) { Some("d") })
    assert_equal Some("d"), (none.or(none, none) { Some("d") })
    assert_equal none, (none.or(none, none) { none })

    # block is not executed if a present option is found before
    assert_equal some, (some.or { raise "error" })
    assert_equal Some("b"), (none.or(Some("b")) { raise "error" })
    assert_raise { none.or { raise "error" } }
    assert_raise { none.or(none) { raise "error" } }

    # every parameter should be an Option
    assert_raise(TypeError) { some.or(1) }
    assert_raise(TypeError) { none.or(1) }
    assert_raise(TypeError) { some.or(Some("b"), 1) }

    # block return type is checked only when executed
    assert_equal some, (some.or { 1 })
    assert_raise(TypeError) { none.or { 1 } }
    assert_equal Some("b"), (none.or(Some("b")) { 1 })
    assert_raise(TypeError) { none.or(none) { 1 } }
  end
  test "and" do
    # call the block if the two options are present
    assert_equal Some("aa"), some.and(some) { |a, b| a + b }
    assert_equal none, none.and(some) { |a, b| a + b }
    assert_equal none, some.and(none) { |a, b| a + b }
    assert_equal none, none.and(none) { |a, b| a + b }

    # call the block if all options are present
    assert_equal Some("aaaa"), some.and(some, some, some) { |a, b, c, d| a + b + c + d }
    assert_equal none, none.and(some, some, some) { |a, b, c, d| a + b + c + d }
    assert_equal none, some.and(none, some, some) { |a, b, c, d| a + b + c + d }
    assert_equal none, some.and(some, none, some) { |a, b, c, d| a + b + c + d }

    # every parameter should be an Option
    assert_raise(TypeError) { some.and(1) { |a, b| a + b } }
    assert_raise(TypeError) { none.and(1) { |a, b| a + b } }
    assert_raise(TypeError) { some.and(some, 1, none) { |a, b, c, d| a + b + c + d } }
  end
  test "to_s" do
    assert_equal "Some(a)", some.to_s
    assert_equal "None", none.to_s
    assert_equal 'Some("a")', some.inspect
    assert_equal "None", none.inspect
  end
  test "to_a" do
    assert_equal ["a"], some.to_a
    assert_equal [[]], Some([]).to_a
    assert_equal [1, 2, 3], Some([1, 2, 3]).to_a
    assert_equal [], none.to_a
  end
  test "fluent api" do
    assert_equal Some("A"), some.upcase
    assert_equal Some(%w[a b]), Some("a,b").split(",")
    assert_equal Some(2), Some(1) + 1
    assert_equal Some(2), Some(1) + Some(1)
    assert_equal Some([1, 2]), Some([1]) + [2]
    assert_equal none, none.upcase
    assert_equal none, none + 1
    assert_equal none, none + Some(1)
    assert_equal none, none.bad
    assert_raise(NoMethodError) { some.bad }
    assert_raise(TypeError) { Some([1]) + 2 }
    assert_raise(get_error { 1 + none }.class) { Some(1) + none }
  end
  test "Enumerable" do
    assert_equal Some("a"), some.select { |v| v == "a" }
    assert_equal none, some.select { |v| v == "b" }
    assert_equal none, none.select { |v| v == "a" }

    assert_equal Some("a"), Some(Some(some)).flatten
    assert_equal Some("a"), Some(some).flatten
    assert_equal Some("a"), some.flatten
    assert_equal none, Some(none).flatten
    assert_equal none, none.flatten

    assert_equal 7, Some(2).inject(5) { |acc, cur| acc + cur }
    assert_equal 5, none.inject(5) { |acc, cur| acc + cur }
    assert_equal Some(3), Some(2).inject(Some(1)) { |acc, cur| acc + cur }
    assert_equal Some(3), Some([1, 2]).inject(Some(0)) { |acc, cur| acc + cur }
    assert_equal 3, Some([1, 2]).inject(0) { |acc, cur| acc + cur }

    assert_equal true, some.all? { |v| v == "a" }
    assert_equal false, some.all? { |v| v == "b" }
    assert_equal true, none.all? { |v| v == "a" }
    assert_equal true, none.all? { |v| v == "b" }

    assert_equal 1, some.length
    assert_equal 0, none.length
  end
  test "case" do
    def assert_case(value, matching, not_matching)
      case value
      when not_matching
        fail("not_matching predicate (#{not_matching}) had a match")
      when matching
        nil
      else
        fail("matching predicate (#{matching}) didn't match")
      end
    end

    assert_case(Some(1), Option::Some, Option::None)
    assert_case(none, Option::None, Option::Some)
    assert_case(Some(1), Some(1), Some(2))
    assert_case(Some(1), Option::AbstractClass, NilClass)
    assert_case(Some(1), Option, Numeric)
    assert_case(1, Numeric, Option)
  end
  test "monad laws" do
    [
      [1, proc { |x| Some(x + 2) }, proc { |x| Some(x * 3) }],
      [3, proc { |x| Some(x + 2) }, proc { |x| none }],
      ["a", proc { |x| Some(x + "b") }, proc { |x| Some(x + "c") }]
    ].map { |x, f, g|
      assert_equal f.yield(x), Some(x).flat_map { |a| f.yield(a) } # left identity
      assert_equal Some(x), Some(x).flat_map { |a| Some(a) } # right identity
      v1 = Some(x).flat_map { |a| f.yield(a) }.flat_map { |b| g.yield(b) }
      v2 = Some(x).flat_map { |a| f.yield(a).flat_map { |b| g.yield(b) } }
      assert_equal v1, v2 # associativity
    }
  end
  test "extensions should not be loaded/unloaded twice" do
    Option.load_extensions
    assert_raise(RuntimeError) { Option.load_extensions }
    Option.unload_extensions
    assert_raise(RuntimeError) { Option.unload_extensions }
  end
  test "extension methods" do
    assert_raise(NoMethodError) { "test".option }
    assert_raise(NoMethodError) { nil.option }

    Option.load_extensions
    assert_equal Some("test"), "test".option
    assert_equal none, nil.option
    Option.unload_extensions

    assert_raise(NoMethodError) { "test".option }
    assert_raise(NoMethodError) { nil.option }

    Option.with_extensions do
      assert_equal Some("test"), "test".option
      assert_equal none, nil.option
    end

    assert_raise(NoMethodError) { "test".option }
    assert_raise(NoMethodError) { nil.option }
  end

  private

  def Some(value)
    Option::Some.new(value)
  end

  def get_error
    if block_given?
      begin
        yield
        nil
      rescue => error
        error
      end
    else
      raise(ArgumentError, "Expects a block")
    end
  end
end
