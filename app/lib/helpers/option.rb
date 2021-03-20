# Option implementation, inspired from Scala and https://medium.com/bettersharing/option-pattern-in-ruby-7b0f7c5abdb6

def Some(value)
  Option::Some.new(value)
end

def None
  Option::None.instance
end

def Option(value)
  value.nil? ? None() : Some(value)
end

module Option
  class NoSuchElementError < StandardError
  end

  def self.is?(other)
    other.is_a?(AbstractClass)
  end

  def self.expected!(value)
    raise(TypeError, "expect Option, got #{value.inspect} (#{value.class})") unless Option.is?(value)
    value
  end

  def self.===(other)
    Option.is?(other)
  end

  class AbstractClass
    include Enumerable
    private_class_method :new, :allocate

    ([:each, :flatten, :length] + Enumerable.instance_methods).each do |enumerable_method|
      define_method(enumerable_method) do |*args, &block|
        res = to_a.send(enumerable_method, *args, &block)
        if res.is_a?(Array)
          some? ? Option(res.first) : self
        else
          res
        end
      end
    end

    def some?
      instance_of?(Some)
    end

    def none?
      !some?
    end

    def present?
      some? ? get_or_raise.present? : false
    end

    def blank?
      some? ? get_or_raise.blank? : true
    end

    def get_or_else(default = nil)
      throw NotImplementedError
    end

    def get_or_nil
      get_or_else(nil)
    end

    def get_or_raise(error = NoSuchElementError)
      get_or_else { raise error }
    end

    def map
      raise(TypeError, "a block is expected") unless block_given?
      some? ? Option(yield(get_or_raise)) : self
    end

    def flat_map
      raise(TypeError, "a block is expected") unless block_given?
      some? ? Option.expected!(yield(get_or_raise)) : self
    end

    def fold(if_empty)
      raise(TypeError, "a block is expected") unless block_given?
      some? ? yield(get_or_raise) : if_empty
    end

    def has
      raise(TypeError, "a block is expected") unless block_given?
      some? ? Option.expect_bool!(yield(get_or_raise)) : false
    end

    def or(other = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !other.nil?
      Option.expected!(block_given? ? None() : other)
      some? ? self : Option.expected!(block_given? ? yield : other)
    end

    def and(other)
      raise(TypeError, "a block is expected") unless block_given?
      Option.expected!(other)
      some? ? other.map { |o| yield(get_or_raise, o) } : self
    end

    def to_s
      some? ? "Some(#{get_or_raise})" : "None"
    end

    def inspect
      some? ? "Some(#{get_or_raise.inspect})" : "None"
    end

    def to_a
      if some?
        value = get_or_raise
        value.is_a?(Enumerable) && value.any? ? value.to_a : [value]
      else
        []
      end
    end

    def to_ary
      to_a
    end

    def eql?(other)
      self == other
    end

    def hash
      get_or_nil.hash
    end

    def ==(other)
      other.instance_of?(self.class) && (some? ? other.get_or_raise == get_or_raise : true)
    end

    def ===(other)
      other.instance_of?(self.class) && (some? ? other.get_or_raise === get_or_raise : true)
    end

    def respond_to_missing?(name, include_private = false)
      some? ? get_or_raise.respond_to?(name, include_private) : true
    end

    def method_missing(name, *args, &block)
      if some?
        unwrapped_args = args.map { |a| a.instance_of?(Some) ? a.get_or_raise : a }
        Some(get_or_raise.send(name, *unwrapped_args, &block))
      else
        self
      end
    end
  end

  class Some < AbstractClass
    public_class_method :new

    def initialize(value)
      @value = value
    end

    def get_or_else(default = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !default.nil?
      @value
    end
  end

  class None < AbstractClass
    include Singleton

    def get_or_else(default = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !default.nil?
      block_given? ? yield : default
    end
  end

  def self.load_extensions
    Object.new.respond_to?(:option) ? raise("Object already has :option method") : Object.send(:define_method, :option) { Option(self) }
  end

  def self.unload_extensions
    Object.new.respond_to?(:option) ? Object.send(:undef_method, :option) : raise("No :option method in Object")
  end

  def self.with_extensions
    raise(TypeError, "a block is expected") unless block_given?
    load_extensions
    yield
    unload_extensions
  end

  private

  def self.expect_bool!(value)
    return value if value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
    raise(ArgumentError, "expect Boolean, got #{value.inspect} (#{value.class})")
  end
end
