module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate!

      def login
        user = User.find_by(email: login_params[:email].to_s.strip.downcase)

        if user&.authenticate(login_params[:password].to_s)
          render json: { token: user.generate_token_for(:auth), user: UserSerializer.call(user) }
        else
          render_error("Invalid email or password", :unauthorized)
        end
      end

      private

      def login_params
        params.permit(:email, :password)
      end
    end
  end
end
