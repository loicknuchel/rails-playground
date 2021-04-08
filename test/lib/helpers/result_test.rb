require "test_helper"
require "helpers/result"

class ResultTest < ActiveSupport::TestCase
  error = NameError.new("err")
  success = Result::Success.new("a")
  failure = Result::Failure.new(error)

  test "result creation" do
    assert_equal success, Success("a")
    assert_equal failure, Failure(error)
    assert_equal Success(5), Result.try { 10 / 2 }
    assert_equal "divided by 0", Result.try { 10 / 0 }.error_or_nil.message
    assert_raise(NoMethodError) { Result.new("a") }
    assert_raise(NoMethodError) { Result::AbstractClass.new("a") }
  end
  test "success?" do
    assert_equal true, success.success?
    assert_equal false, failure.success?
    assert_equal true, success.present?
    assert_equal false, failure.present?
  end
  test "failure?" do
    assert_equal false, success.failure?
    assert_equal true, failure.failure?
    assert_equal false, success.blank?
    assert_equal true, failure.blank?
  end
  test "get_or_else" do
    assert_equal "a", success.get_or_else("b")
    assert_equal "a", success.get_or_else { "b" }
    assert_equal "b", failure.get_or_else("b")
    assert_equal "b", failure.get_or_else { "b" }
    assert_raise(ArgumentError) { success.get_or_else("b") { "b" } }
    assert_raise(ArgumentError) { failure.get_or_else("b") { "b" } }
  end
  test "get_or_nil" do
    assert_equal "a", success.get_or_nil
    assert_nil failure.get_or_nil
  end
  test "get_or_raise" do
    assert_equal "a", success.get_or_raise(ArgumentError)
    assert_raise(error.class) { failure.get_or_raise }
    assert_raise(ArgumentError) { failure.get_or_raise(ArgumentError) }
  end
  test "error_or_else" do
    assert_equal error, failure.error_or_else(ArgumentError)
    assert_equal error, failure.error_or_else { ArgumentError }
    assert_equal ArgumentError, success.error_or_else(ArgumentError)
    assert_equal ArgumentError, success.error_or_else { ArgumentError }
    assert_raise(ArgumentError) { success.error_or_else(ArgumentError) { ArgumentError } }
    assert_raise(ArgumentError) { failure.error_or_else(ArgumentError) { ArgumentError } }
  end
  test "error_or_nil" do
    assert_equal error, failure.error_or_nil
    assert_nil success.error_or_nil
  end
  test "error_or_raise" do
    assert_equal error, failure.error_or_raise(ArgumentError)
    assert_raise(Result::NoSuchElementError) { success.error_or_raise }
    assert_raise(ArgumentError) { success.error_or_raise(ArgumentError) }
  end
  test "map" do
    assert_equal Success("A"), success.map { |v| v.upcase }
    assert_equal Success(nil), success.map { |v| nil }
    assert_equal failure, failure.map { |v| v.upcase }
    assert_equal Success(Success("ab")), success.map { |v| Success(v + "b") }
  end
  test "flat_map" do
    assert_equal Success("ab"), success.flat_map { |v| Success(v + "b") }
    assert_equal failure, success.flat_map { |v| failure }
    assert_equal failure, failure.flat_map { |v| Success("b") }
    assert_equal failure, failure.flat_map { |v| failure }
    assert_equal Success(6), Success(1).flat_map { |a| Success(2).flat_map { |b| Success(3).flat_map { |c| Success(a + b + c) } } }
    assert_equal Success(6), Success(1).flat_map { |a| Success(2).flat_map { |b| Success(3).map { |c| a + b + c } } }
    assert_equal Success(Success("a")), success.flat_map { |v| Success(Success(v)) }
  end
  test "map_error" do
    assert_equal Failure("A"), Failure("a").map_error { |v| v.upcase }
    assert_equal Failure(nil), Failure("a").map_error { |v| nil }
    assert_equal success, success.map_error { |v| v.upcase }
    assert_equal Failure(Failure("ab")), Failure("a").map_error { |v| Failure(v + "b") }
  end
  test "fold" do
    assert_equal "a", success.fold(->(error) { error.message }, ->(value) { value.to_s })
    assert_equal "err", failure.fold(->(error) { error.message }, ->(value) { value.to_s })
    assert_raise(TypeError) { success.fold("a", ->(value) { value.to_s }) }
    assert_raise(TypeError) { success.fold(->(error) { error.message }, "a") }
  end
  test "rescue_with" do
    assert_equal success, success.rescue_with { Success("b") }
    assert_equal success, success.rescue_with { Failure("b") }
    assert_equal Success("b"), failure.rescue_with { Success("b") }
    assert_equal Failure("b"), failure.rescue_with { Failure("b") }
    assert_raise(TypeError) { failure.rescue_with { "b" } }
    assert_raise(TypeError) { success.rescue_with }
    assert_raise(ArgumentError) { success.rescue_with(1) }
  end
  test "or" do
    assert_equal success, success.or(Success("b"))
    assert_equal Success("b"), failure.or(Success("b"))
    assert_equal success, success.or(failure)
    assert_equal failure, failure.or(failure)
    assert_equal success, success.or { Success("b") }
    assert_equal Success("b"), failure.or { Success("b") }
    assert_raise(TypeError) { success.or(1) }
    assert_equal success, success.or { 1 } # block not evaluated so can't assert its result
    assert_raise(TypeError) { failure.or(1) }
    assert_raise(TypeError) { failure.or { 1 } }
    assert_raise(ArgumentError) { success.or(Success(1)) { Success(1) } }
    assert_raise(ArgumentError) { failure.or(Success(1)) { Success(1) } }
    assert_equal success, success.or { raise "error" }
  end
  test "and" do
    assert_equal Success("aa"), success.and(success) { |a, b| a + b }
    assert_equal failure, failure.and(success) { |a, b| a + b }
    assert_equal failure, success.and(failure) { |a, b| a + b }
    assert_equal failure, failure.and(failure) { |a, b| a + b }
    assert_raise(TypeError) { success.and(1) { |a, b| a + b } }
    assert_raise(TypeError) { failure.and(1) { |a, b| a + b } }
  end
  test "combine" do
    s1, s2, s3, s4 = Success("a"), Success("b"), Success("c"), Success("d")
    f1, f2, f3 = Failure("e1"), Failure("e2"), Failure("e3")

    assert_equal Success("ab"), s1.combine(s2) { |a, b| a + b }
    assert_equal Success("abc"), s1.combine(s2, s3) { |a, b, c| a + b + c }
    assert_equal Success("abcd"), s1.combine(s2, s3, s4) { |a, b, c, d| a + b + c + d }
    assert_equal f1, f1.combine(s1) { |a, b| a + b }
    assert_equal f1, s1.combine(f1) { |a, b| a + b }
    assert_equal Failure(%w[e1 e2]), f1.combine(f2) { |a, b| a + b }
    assert_equal Failure(%w[e1 e2 e3]), f1.combine(f2, f3) { |a, b, c| a + b + c }
    assert_equal Failure(%w[e1 e2 e3]), f1.combine(f2) { |a, b| a + b }.combine(f3) { |ab, c| ab + c }
    assert_raise(TypeError) { s1.combine(s2) }
    assert_raise(TypeError) { s1.combine("bad") { |a, b| a + b } }
  end
  test "to_s" do
    assert_equal "Success(a)", success.to_s
    assert_equal "Failure(err)", failure.to_s
    assert_equal 'Success("a")', success.inspect
    assert_equal "Failure(#<NameError: err>)", failure.inspect
  end
  test "to_a" do
    assert_equal ["a"], success.to_a
    assert_equal [[]], Success([]).to_a
    assert_equal [1, 2, 3], Success([1, 2, 3]).to_a
    assert_equal [], failure.to_a
  end
  test "to_option" do
    assert_equal Some("a"), success.to_option
    assert_equal None(), failure.to_option
  end
  test "fluent api" do
    assert_equal Success("A"), success.upcase
    assert_equal Success(%w[a b]), Success("a,b").split(",")
    assert_equal Success(2), Success(1) + 1
    assert_equal Success(2), Success(1) + Success(1)
    assert_equal Success([1, 2]), Success([1]) + [2]
    assert_equal failure, failure.upcase
    assert_equal failure, failure + 1
    assert_equal failure, failure + Success(1)
    assert_equal failure, failure.bad
    assert_raise(NoMethodError) { success.bad }
    assert_raise(TypeError) { Success([1]) + 2 }
    assert_raise(get_error { 1 + failure }.class) { Success(1) + failure }
  end
  test "Enumerable" do
    assert_equal Success("a"), success.select { |v| v == "a" }
    assert_equal Failure(Result::NoSuchElementError), success.select { |v| v == "b" }
    assert_equal failure, failure.select { |v| v == "a" }

    assert_equal Success("a"), Success(Success(success)).flatten
    assert_equal Success("a"), Success(success).flatten
    assert_equal Success("a"), success.flatten
    assert_equal Failure(Result::NoSuchElementError), Success(failure).flatten
    assert_equal failure, failure.flatten

    assert_equal 7, Success(2).inject(5) { |acc, cur| acc + cur }
    assert_equal 5, failure.inject(5) { |acc, cur| acc + cur }
    assert_equal Success(3), Success(2).inject(Success(1)) { |acc, cur| acc + cur }
    assert_equal Success(3), Success([1, 2]).inject(Success(0)) { |acc, cur| acc + cur }
    assert_equal 3, Success([1, 2]).inject(0) { |acc, cur| acc + cur }

    assert_equal true, success.all? { |v| v == "a" }
    assert_equal false, success.all? { |v| v == "b" }
    assert_equal true, failure.all? { |v| v == "a" }
    assert_equal true, failure.all? { |v| v == "b" }

    assert_equal 1, success.length
    assert_equal 0, failure.length
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

    assert_case(Success(1), Result::Success, Result::Failure)
    assert_case(Failure(NameError), Result::Failure, Result::Success)
    assert_case(Success(1), Success(1), Success(2))
    assert_case(Success(1), Result::AbstractClass, NilClass)
    assert_case(Success(1), Result, Numeric)
    assert_case(1, Numeric, Result)
  end
  test "monad laws" do
    [
      [1, proc { |x| Success(x + 2) }, proc { |x| Success(x * 3) }],
      [3, proc { |x| Success(x + 2) }, proc { |x| Failure(NameError) }],
      ["a", proc { |x| Success(x + "b") }, proc { |x| Success(x + "c") }]
    ].map { |x, f, g|
      assert_equal f.yield(x), Success(x).flat_map { |a| f.yield(a) } # left identity
      assert_equal Success(x), Success(x).flat_map { |a| Success(a) } # right identity
      v1 = Success(x).flat_map { |a| f.yield(a) }.flat_map { |b| g.yield(b) }
      v2 = Success(x).flat_map { |a| f.yield(a).flat_map { |b| g.yield(b) } }
      assert_equal v1, v2 # associativity
    }
  end
  test "extensions should not be loaded/unloaded twice" do
    Result.load_extensions
    assert_raise(RuntimeError) { Result.load_extensions }
    Result.unload_extensions
    assert_raise(RuntimeError) { Result.unload_extensions }
  end
  test "extension methods" do
    assert_raise(NoMethodError) { "test".success }
    assert_raise(NoMethodError) { nil.success }
    assert_raise(NoMethodError) { "err".failure }

    Result.load_extensions
    assert_equal Success("test"), "test".success
    assert_equal Success(nil), nil.success
    assert_equal Failure("err"), "err".failure
    Result.unload_extensions

    assert_raise(NoMethodError) { "test".success }
    assert_raise(NoMethodError) { nil.success }
    assert_raise(NoMethodError) { "err".failure }

    Result.with_extensions do
      assert_equal Success("test"), "test".success
      assert_equal Success(nil), nil.success
      assert_equal Failure("err"), "err".failure
    end

    assert_raise(NoMethodError) { "test".success }
    assert_raise(NoMethodError) { nil.success }
    assert_raise(NoMethodError) { "err".failure }
  end

  private

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
