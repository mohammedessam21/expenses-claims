module Api
  module V1
    module Review
      class ClaimsController < BaseController
        before_action :set_claim, except: :index

        def index
          claims = company_claims.includes(:category, :employee, :reviewer).order(created_at: :desc)
          claims = claims.where(status: params[:status]) if params[:status].present?
          render json: { claims: claims.map { |claim| ClaimSerializer.call(claim) } }
        end

        def show
          render_claim(@claim)
        end

        def start_review
          render_claim(workflow.start_review)
        end

        def approve
          render_claim(workflow.approve)
        end

        def reject
          render_claim(workflow.reject(params.permit(:reason)[:reason]))
        end

        def return_claim
          render_claim(workflow.return_claim(params.permit(:comment)[:comment]))
        end

        private

        def company_claims
          current_user.company.claims
        end

        def set_claim
          @claim = company_claims.find(params[:id])
        end

        def workflow
          ClaimWorkflow.new(@claim, current_user)
        end
      end
    end
  end
end
