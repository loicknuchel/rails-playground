class RoleType < ActiveRecord::Type::Value
  def cast(value)
    object_to_role(value)
  end

  def serialize(value)
    role_to_integer(value)
  end

  private

  def object_to_role(value)
    return nil if value.nil?
    return value if value.instance_of?(Role)
    return Role.find_by_id!(value) if value.instance_of?(Integer)
    Role.find_by_name!(value)
  end

  def role_to_integer(role)
    return nil if role.nil?
    return role.id if role.instance_of?(Role)
    raise(ArgumentError, "#{role.inspect} is not a valid Role")
  end
end
