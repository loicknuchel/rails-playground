class SessionsController < ApplicationController
  def create
    @user = User.find_by(email: params[:email], password: params[:password])
    if @user
      session[:current_user_id] = @user.id
      redirect = cookies[:login_redirect] || params[:redirect] || root_path
      cookies.delete(:login_redirect)
      redirect_to redirect
    else
      flash.now[:error] = "Invalid credentials"
      render :new
    end
  end

  def destroy
    session.delete(:current_user_id)
    @_current_user = nil
    redirect_to request.referer || root_path, notice: "You have successfully logged out."
  end
end
