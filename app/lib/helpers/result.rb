def Success(value)
  Result::Success.new(value)
end

def Failure(error)
  Result::Failure.new(error)
end

module Result
  class NoSuchElementError < StandardError
  end

  def self.expected!(value)
    raise(TypeError, "expect Result, got #{value.inspect} (#{value.class})") unless value.is_a?(AbstractClass)
    value
  end

  def self.try
    raise(TypeError, "a block is expected") unless block_given?
    begin
      Success(yield)
    rescue => error
      Failure(error)
    end
  end

  def self.===(other)
    other.is_a?(AbstractClass)
  end

  class AbstractClass
    include Enumerable
    private_class_method :new, :allocate

    ([:each, :flatten, :length] + Enumerable.instance_methods).each do |enumerable_method|
      define_method(enumerable_method) do |*args, &block|
        res = to_a.send(enumerable_method, *args, &block)
        if res.is_a?(Array)
          if success?
            res.empty? ? Failure(NoSuchElementError) : Success(res.first)
          else
            self
          end
        else
          res
        end
      end
    end

    def success?
      instance_of?(Success)
    end

    def failure?
      !success?
    end

    def present?
      success? ? get_or_raise.present? : false
    end

    def blank?
      success? ? get_or_raise.blank? : true
    end

    def get_or_else(default = nil)
      throw NotImplementedError
    end

    def get_or_nil
      get_or_else(nil)
    end

    def get_or_raise(error = nil)
      get_or_else do
        e = error || error_or_raise
        raise(e) if e.is_a?(StandardError) || e.is_a?(StandardError.class)
        raise(NoSuchElementError, "Failure(#{e.inspect}).get_or_raise")
      end
    end

    def error_or_else(default = nil)
      throw NotImplementedError
    end

    def error_or_nil
      error_or_else(nil)
    end

    def error_or_raise(error = nil)
      error_or_else do
        raise(error) if error.is_a?(StandardError) || error.is_a?(StandardError.class)
        raise(NoSuchElementError, "Success(#{get_or_raise.inspect}).error_or_raise")
      end
    end

    def map
      raise(TypeError, "a block is expected") unless block_given?
      success? ? Success(yield(get_or_raise)) : self
    end

    def flat_map
      raise(TypeError, "a block is expected") unless block_given?
      success? ? Result.expected!(yield(get_or_raise)) : self
    end

    def map_error
      raise(TypeError, "a block is expected") unless block_given?
      success? ? self : Failure(yield(error_or_raise))
    end

    def fold(on_failure, on_success)
      raise(TypeError, "expect failure Proc for 1st param, got #{on_failure.inspect} (#{on_failure.class})") unless on_failure.instance_of?(Proc)
      raise(TypeError, "expect success Proc for 2nd param, got #{on_success.inspect} (#{on_success.class})") unless on_success.instance_of?(Proc)
      success? ? on_success.call(get_or_raise) : on_failure.call(error_or_raise)
    end

    def rescue_with
      raise(TypeError, "a block is expected") unless block_given?
      success? ? self : Result.expected!(yield(error_or_raise))
    end

    def or(other = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !other.nil?
      Result.expected!(block_given? ? Failure(nil) : other)
      success? ? self : Result.expected!(block_given? ? yield : other)
    end

    def and(other)
      raise(TypeError, "a block is expected") unless block_given?
      Result.expected!(other)
      success? ? other.map { |o| yield(get_or_raise, o) } : self
    end

    def combine(*others)
      raise(TypeError, "a block is expected") unless block_given?
      raise(TypeError, "expect all parameters to be Result") unless others.all? { |r| r.is_a?(AbstractClass) }
      results = [self] + others
      if results.all? { |r| r.instance_of?(Success) }
        Success(yield(*results.map(&:get_or_raise)))
      else
        errors = results.select { |r| r.instance_of?(Failure) }.map(&:error_or_raise).flatten(1)
        Failure(errors.length == 1 ? errors.first : errors)
      end
    end

    def to_s
      success? ? "Success(#{get_or_raise})" : "Failure(#{error_or_raise})"
    end

    def inspect
      success? ? "Success(#{get_or_raise.inspect})" : "Failure(#{error_or_raise.inspect})"
    end

    def to_a
      if success?
        value = get_or_raise
        value.is_a?(Enumerable) && value.any? ? value.to_a : [value]
      else
        []
      end
    end

    def to_ary
      to_a
    end

    def to_option
      success? ? Some(get_or_raise) : None()
    end

    def eql?(other)
      self == other
    end

    def hash
      get_or_nil.hash
    end

    def ==(other)
      other.instance_of?(self.class) && (success? ? other.get_or_raise == get_or_raise : other.error_or_raise == error_or_raise)
    end

    def ===(other)
      other.instance_of?(self.class) && (success? ? other.get_or_raise === get_or_raise : other.error_or_raise === error_or_raise)
    end

    def respond_to_missing?(name, include_private = false)
      success? ? get_or_raise.respond_to?(name, include_private) : true
    end

    def method_missing(name, *args, &block)
      if success?
        unwrapped_args = args.map { |a| a.instance_of?(Success) ? a.get_or_raise : a }
        Success(get_or_raise.send(name, *unwrapped_args, &block))
      else
        self
      end
    end
  end

  class Success < AbstractClass
    public_class_method :new

    def initialize(value)
      @value = value
    end

    def get_or_else(default = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !default.nil?
      @value
    end

    def error_or_else(default = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !default.nil?
      block_given? ? yield : default
    end
  end

  class Failure < AbstractClass
    public_class_method :new

    def initialize(error)
      @error = error
    end

    def get_or_else(default = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !default.nil?
      block_given? ? yield : default
    end

    def error_or_else(default = nil)
      raise(ArgumentError, "expect block or value, not both") if block_given? && !default.nil?
      @error
    end
  end

  def self.load_extensions
    Object.new.respond_to?(:success) ? raise("Object already has :success method") : Object.send(:define_method, :success) { Success(self) }
    Object.new.respond_to?(:failure) ? raise("Object already has :failure method") : Object.send(:define_method, :failure) { Failure(self) }
  end

  def self.unload_extensions
    Object.new.respond_to?(:success) ? Object.send(:undef_method, :success) : raise("No :success method in Object")
    Object.new.respond_to?(:failure) ? Object.send(:undef_method, :failure) : raise("No :failure method in Object")
  end

  def self.with_extensions
    raise(TypeError, "a block is expected") unless block_given?
    load_extensions
    yield
    unload_extensions
  end
end
