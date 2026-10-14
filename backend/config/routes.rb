Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      get "me", to: "me#show"

      resources :categories, only: :index
      resources :claims, only: %i[index show create] do
        member do
          post :resubmit
          post :withdraw
        end
      end

      namespace :review do
        resources :claims, only: %i[index show] do
          member do
            post :start_review
            post :approve
            post :reject
            post :return, action: :return_claim
          end
        end
        resources :categories, only: %i[index show create update]
      end
    end
  end

  match "*path", to: "application#route_not_found", via: :all
end
