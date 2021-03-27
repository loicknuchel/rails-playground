class StatusType < ActiveRecord::Type::String
  def cast(value)
    object_to_status(value)
  end

  def serialize(value)
    status_to_string(value)
  end

  private

  def object_to_status(value)
    return nil if value.nil?
    return value if value.instance_of?(Status)
    Status.find!(value)
  end

  def status_to_string(status)
    return nil if status.nil?
    return status.value if status.instance_of?(Status)
    raise(ArgumentError, "#{status.inspect} is not a valid Status")
  end
end
