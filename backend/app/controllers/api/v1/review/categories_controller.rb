module Api
  module V1
    module Review
      class CategoriesController < BaseController
        before_action :set_category, only: %i[show update]

        def index
          categories = company_categories.order(:name_en)
          render json: { categories: categories.map { |category| CategorySerializer.call(category) } }
        end

        def show
          render_category(@category)
        end

        def create
          render_category(company_categories.create!(category_params), status: :created)
        end

        def update
          @category.update!(category_params)
          render_category(@category)
        end

        private

        def company_categories
          current_user.company.categories
        end

        def set_category
          @category = company_categories.find(params[:id])
        end

        def category_params
          params.expect(category: %i[name_en name_ar limit_halalas active])
        end

        def render_category(category, status: :ok)
          render json: { category: CategorySerializer.call(category) }, status: status
        end
      end
    end
  end
end
