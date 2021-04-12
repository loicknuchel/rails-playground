class ApplicationController < ActionController::Base
  before_action :_current_user
  around_action :log

  private

  def _current_user
    @_current_user = Option(session[:current_user_id] && User.find_by(id: session[:current_user_id])) if @_current_user.nil? || @_current_user.none?
  end

  def require_login
    if @_current_user.none?
      cookies[:login_redirect] = request.path
      redirect_to auth.login_path
    end
  end

  def require_roles(*roles)
    unless @_current_user.has { |u| u.any_role?(roles) }
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
