module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate!

      rescue_from ClaimWorkflow::InvalidTransition, with: :render_unprocessable
      rescue_from ClaimWorkflow::NotPermitted, with: :render_forbidden

      private

      attr_reader :current_user

      def authenticate!
        @current_user = User.find_by_token_for(:auth, bearer_token)
        render_error("Authentication required", :unauthorized) unless @current_user
      end

      def bearer_token
        request.authorization.to_s[/\ABearer (.+)\z/, 1].to_s
      end

      def render_claim(claim, status: :ok)
        render json: { claim: ClaimSerializer.detail(claim, current_user) }, status: status
      end

      def render_unprocessable(exception)
        render_error(exception.message, :unprocessable_content)
      end

      def render_forbidden(exception)
        render_error(exception.message, :forbidden)
      end
    end
  end
end
