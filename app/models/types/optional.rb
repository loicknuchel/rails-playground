require "helpers/option"

# cf https://api.rubyonrails.org/classes/ActiveRecord/Attributes/ClassMethods.html
# also https://apidock.com/rails/ActiveRecord/Attributes/ClassMethods/attribute
class Optional < ActiveRecord::Type::Value
  def initialize(opts)
    @allow_blank = expect_bool!(opts.fetch(:allow_blank, false))
    @type = ActiveRecord::Type.lookup(opts[:type], *opts.except(:type, :allow_blank))
    super()
  end

  def cast(value)
    object_to_option(value)
  end

  def serialize(option)
    option_to_value(option)
  end

  def type
    @type.type
  end

  def serializable?(value)
    @type.serializable?(value)
  end

  private

  def expect_bool!(value)
    return value if value.instance_of?(TrueClass) || value.instance_of?(FalseClass)
    raise(ArgumentError, "expect Boolean, got #{value.inspect} (#{value.class})")
  end

  def object_to_option(value)
    Option.is?(value) ? value : format(Option(@type.cast(value)))
  end

  def option_to_value(option)
    @type.serialize(format(option).get_or_nil)
  end

  def format(opt)
    @allow_blank ? opt : opt.select { |str| !str.blank? }
  end
end
