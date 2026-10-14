module Api
  module V1
    module Review
      class BaseController < Api::V1::BaseController
        before_action :require_approver!

        private

        def require_approver!
          render_error("Approver access required", :forbidden) unless current_user.approver?
        end
      end
    end
  end
end
