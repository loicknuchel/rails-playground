module Auth
  class SessionsController < ApplicationController
    def new
      if current_user.some?
        redirect = cookies[:login_redirect] || params[:redirect] || main_app.root_path
        cookies.delete(:login_redirect)
        redirect_to redirect
      end
    end

    def create
      @user = User.find_by(email: params[:email], password: params[:password])
      if @user
        session[:current_user_id] = @user.id
        redirect = cookies[:login_redirect] || params[:redirect] || main_app.root_path
        cookies.delete(:login_redirect)
        redirect_to redirect
      else
        flash.now[:error] = "Invalid credentials"
        render :new
      end
    end

    def destroy
      session.delete(:current_user_id)
      destroy_current_user
      redirect_to request.referer || main_app.root_path, notice: "You have successfully logged out."
    end
  end
end
