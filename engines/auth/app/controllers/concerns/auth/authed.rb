# @current_user attribute should not be accessed outside of this file, use current_user method instead
module Auth
  module Authed
    extend ActiveSupport::Concern
    included do
      before_action :current_user

      def current_user
        if @current_user.nil? || @current_user.none?
          @current_user = Option(session[:current_user_id] && User.find_by(id: session[:current_user_id]))
        else
          @current_user
        end
      end

      helper_method :current_user

      def destroy_current_user
        @current_user = None()
      end

      def require_login
        if current_user.none?
          cookies[:login_redirect] = request.path
          redirect_to auth.login_path
        end
      end

      def require_roles(*roles)
        unless current_user.has { |u| u.any_role?(roles) }
          unauthorized
        end
      end

      def require_role(role)
        require_roles(role)
      end

      private

      def unauthorized
        render file: "#{Rails.root}/public/401.html", layout: false
      end
    end
  end
end
