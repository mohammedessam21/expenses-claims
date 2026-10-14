module Api
  module V1
    class MeController < BaseController
      def show
        render json: { user: UserSerializer.call(current_user) }
      end
    end
  end
end
