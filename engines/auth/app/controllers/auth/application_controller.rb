module Auth
  class ApplicationController < ActionController::Base
    include Auth::Authed
    layout "layouts/application"
  end
end
