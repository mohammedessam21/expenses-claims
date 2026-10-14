module Api
  module V1
    module Review
      class ClaimsController < BaseController
        DEFAULT_PER_PAGE = 20
        MAX_PER_PAGE = 100

        before_action :set_claim, except: :index

        def index
          page = positive_integer_param(:page, 1)
          return render_error("page must be a positive integer", :unprocessable_content) unless page

          per_page = positive_integer_param(:per_page, DEFAULT_PER_PAGE)
          return render_error("per_page must be a positive integer", :unprocessable_content) unless per_page

          per_page = [per_page, MAX_PER_PAGE].min
          scope = company_claims
          scope = scope.where(status: index_params[:status]) if index_params[:status].present?
          total_count = scope.count
          offset = (page - 1) * per_page
          claims =
            if offset < total_count
              scope.includes(:category, :employee, :reviewer).order(created_at: :desc, id: :desc).limit(per_page).offset(offset)
            else
              []
            end

          render json: {
            claims: claims.map { |claim| ClaimSerializer.call(claim) },
            meta: { page: page, per_page: per_page, total_count: total_count, total_pages: (total_count + per_page - 1) / per_page }
          }
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

        def index_params
          params.permit(:status, :page, :per_page)
        end

        def positive_integer_param(name, default)
          value = index_params[name]
          return default if value.nil?

          number = Integer(value, 10, exception: false) if value.is_a?(String)
          number if number&.positive?
        end
      end
    end
  end
end
