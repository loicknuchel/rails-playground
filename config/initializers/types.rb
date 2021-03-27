require "types/optional"
require "types/status_type"
require "types/role_type"

ActiveRecord::Type.register(:optional, Optional)
ActiveRecord::Type.register(:status, StatusType)
ActiveRecord::Type.register(:role, RoleType)
