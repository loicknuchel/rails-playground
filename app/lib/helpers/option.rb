# Option implementation, inspired from Scala and https://medium.com/bettersharing/option-pattern-in-ruby-7b0f7c5abdb6
module Option
  class NoSuchElementError < StandardError
  end

  def self.empty
    None.instance
  end

  # create an Option from a nillable value
  def self.new(value)
    value.nil? ? Option.empty : Some.new(value)
  end

  # check if a value is an Option
  def self.is?(other)
    other.is_a?(AbstractClass)
  end

  # create an Option from a value that can be nillable or already an Option (useful on migrations)
  def self.from_nillable_or_option(value)
    Option.is?(value) ? value : Option.new(value)
  end

  # assert that the value is an Option and return it
  def self.expected!(value, ctx = '')
    return value if Option.is?(value)
    raise(TypeError, "expect Option#{ctx}, got #{value.inspect} (#{value.class})")
  end

  def self.===(other)
    Option.is?(other)
  end

  class AbstractClass
    include Enumerable
    private_class_method :new, :allocate

    # implement Enumerable methods in Option
    ([:each, :flatten, :length] + Enumerable.instance_methods).each do |enumerable_method|
      define_method(enumerable_method) do |*args, &block|
        res = to_a.send(enumerable_method, *args, &block)
        if res.is_a?(Array)
          some? ? Option.new(res.first) : self
        else
          res
        end
      end
    end

    # avoid using methods such as `some?`, `none?`, `present?` and `blank?`
    # the whole purpose of Option is to avoid having to take care of this
    # prefer methods such as `fold`, `map` or `get_or_else`
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

    # extract the value from the Option, providing the missing case (parameter or block)
    def get_or_else(default = nil)
      raise NotImplementedError
    end

    # avoid using this if you can
    # checking Option presence and the extracting it is not the intended behavior
    # look at better alternatives such as `fold` or `map`
    def get_or_raise(error = NoSuchElementError)
      get_or_else { raise error }
    end

    # !!!avoid this as much as you can!!!
    # use it only for compatibility purpose when the called method expect nillable value and can't be changed
    def get_or_nil
      get_or_else(nil)
    end

    # transform the value inside Option if present
    # this implementation avoid Some(nil) for user friendliness but break the usual map contract (keep monad the same)
    def map
      raise(ArgumentError, "a block is expected") unless block_given?
      some? ? Option.new(yield(get_or_raise)) : self
    end

    # like `map` but when the block return an Option
    def flat_map
      raise(ArgumentError, "a block is expected") unless block_given?
      some? ? Option.expected!(yield(get_or_raise)) : self
    end

    # transform an option into a value, handling both cases
    # `if_empty` can be a value or a parameterless proc
    # `if_present` can be a value or a proc with the option value as parameter or not present if a block is provided
    def fold(if_empty, if_present = nil)
      if (!block_given? && if_present.nil?) || (block_given? && !if_present.nil?)
        raise(ArgumentError, 'present case expected')
      end
      if some?
        return yield(get_or_raise) if block_given?
        return if_present.call(get_or_raise) if !if_present.nil? && if_present.respond_to?(:call)
        if_present
      else
        return if_empty.call if if_empty.respond_to?(:call)
        if_empty
      end
    end

    # check if the value meet a condition, returns a boolean
    def has?
      raise(ArgumentError, "a block is expected") unless block_given?
      some? ? Option.expect_bool!(yield(get_or_raise)) : false
    end

    # returns the first present Option or None
    def or(*alternatives)
      options = [self] + alternatives.each_with_index.map { |o, i| Option.expected!(o, " at index #{i}") }
      found = options.find(&:some?)
      return found unless found.nil?
      return Option.expected!(yield) if block_given?
      Option.empty
    end

    # call the block with the values as parameters only if they are all present
    def and(*complements)
      raise(TypeError, 'a block is expected') unless block_given?
      options = [self] + complements.each_with_index.map { |o, i| Option.expected!(o, " at index #{i}") }
      options.all?(&:some?) ? Option.new(yield(*options.map(&:get_or_raise))) : Option.empty
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

    delegate :hash, to: :get_or_nil

    def ==(other)
      other.instance_of?(self.class) && (some? ? other.get_or_raise == get_or_raise : true)
    end

    # to have friendly matching in case statements
    def ===(other)
      other.instance_of?(self.class) && (some? ? other.get_or_raise === get_or_raise : true)
    end

    def method_missing(name, *args, &block)
      if some?
        unwrapped_args = args.map { |a| Option.is?(a) ? a.get_or_nil : a }
        Option.new(get_or_raise.send(name, *unwrapped_args, &block))
      else
        self
      end
    end

    def respond_to_missing?(name, include_private = false)
      some? ? get_or_raise.respond_to?(name, include_private) : true
    end
  end

  class Some < AbstractClass
    public_class_method :new

    def initialize(value)
      super()
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
    if Object.new.respond_to?(:option)
      raise "Object already has :option method"
    else
      Object.send(:define_method, :option) { Option.new(self) }
    end
  end

  def self.unload_extensions
    if Object.new.respond_to?(:option)
      Object.send(:undef_method, :option)
    else
      raise "No :option method in Object"
    end
  end

  def self.with_extensions
    raise(TypeError, "a block is expected") unless block_given?
    load_extensions
    yield
    unload_extensions
  end

  def self.expect_bool!(value)
    return value if value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
    raise(ArgumentError, "expect Boolean, got #{value.inspect} (#{value.class})")
  end
end
