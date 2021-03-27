require "types/optional"
require "types/status_type"

ActiveRecord::Type.register(:optional, Optional)
ActiveRecord::Type.register(:status, StatusType)
