module Api
  module V1
    class ClaimsController < BaseController
      before_action :set_claim, only: %i[show resubmit withdraw]

      def index
        claims = current_user.claims.includes(:category, :employee, :reviewer).order(created_at: :desc)
        render json: { claims: claims.map { |claim| ClaimSerializer.call(claim) } }
      end

      def show
        render_claim(@claim)
      end

      def create
        attributes = create_params
        category = current_user.company.categories.active.find(attributes.delete(:category_id))
        claim = ClaimWorkflow.submit(employee: current_user, category: category, attributes: attributes)
        render_claim(claim, status: :created)
      end

      def resubmit
        render_claim(ClaimWorkflow.new(@claim, current_user).resubmit(resubmit_params))
      end

      def withdraw
        render_claim(ClaimWorkflow.new(@claim, current_user).withdraw)
      end

      private

      def set_claim
        @claim = current_user.claims.find(params[:id])
      end

      def create_params
        params.expect(claim: %i[category_id amount_halalas description spent_on])
      end

      def resubmit_params
        params.permit(claim: %i[amount_halalas description]).fetch(:claim, {})
      end
    end
  end
end
