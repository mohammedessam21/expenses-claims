module Api
  module V1
    class CategoriesController < BaseController
      def index
        categories = current_user.company.categories.active.order(:name_en)
        render json: { categories: categories.map { |category| CategorySerializer.call(category) } }
      end
    end
  end
end
