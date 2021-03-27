class Status
  attr_reader :value

  def initialize(value)
    @value = value
  end

  def to_s
    "#{self.class.name}(#{value})"
  end

  def inspect
    "#{self.class.name}(#{value.inspect})"
  end

  def ==(other)
    other.class == self.class && other.value == value
  end

  PUBLIC = Status.new("public")
  PRIVATE = Status.new("private")
  ARCHIVED = Status.new("archived")
  private_class_method :new, :allocate

  def self.all
    [PUBLIC, PRIVATE, ARCHIVED]
  end

  def self.find!(value)
    all.find { |s| s.value == value } || raise(ArgumentError, "No Status #{value.inspect}")
  end

  def self.to_hash
    all.each_with_object({}) { |status, hash| hash[status.value.to_sym] = status }.freeze
  end
end
