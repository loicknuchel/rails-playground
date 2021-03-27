class Role
  attr_reader :name, :id

  def initialize(name, id)
    @name, @id = name, id
  end

  def to_s
    "#{self.class.name}(#{name}, #{id})"
  end

  def inspect
    "#{self.class.name}(#{name.inspect}, #{id.inspect})"
  end

  def ==(other)
    other.class == self.class && other.id == id
  end

  ADMIN = Role.new("admin", 0)
  AUTHOR = Role.new("author", 1)
  GUEST = Role.new("guest", 2)
  private_class_method :new, :allocate

  def self.all
    [ADMIN, AUTHOR, GUEST]
  end

  def self.find_by_id!(id)
    all.find { |r| r.id == id } || raise(ArgumentError, "No Role with id #{id.inspect}")
  end

  def self.find_by_name!(name)
    all.find { |r| r.name == name } || raise(ArgumentError, "No Role with name #{name.inspect}")
  end

  def self.to_hash
    all.each_with_object({}) { |role, hash| hash[role.name.to_sym] = role }.freeze
  end
end
