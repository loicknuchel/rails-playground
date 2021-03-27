class ApplicationController < ActionController::Base
  before_action :_current_user
  around_action :log

  private

  def _current_user
    @_current_user ||= session[:current_user_id] && User.find_by(id: session[:current_user_id])
  end

  def require_login
    unless @_current_user
      cookies[:login_redirect] = request.path
      redirect_to login_path
    end
  end

  def require_roles(*roles)
    unless @_current_user&.any_role?(roles)
      unauthorized
    end
  end

  def require_role(role)
    require_roles(role)
  end

  def unauthorized
    render file: "#{Rails.root}/public/401.html", layout: false
  end

  def log
    id = request.uuid
    start = Time.now
    yield
    stop = Time.now
    puts "Request #{id} ran in #{stop - start} sec"
  end
end
