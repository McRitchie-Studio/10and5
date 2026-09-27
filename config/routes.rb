Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :restaurants, only: %i[index show], param: :slug do
    resources :visits, only: :show, param: :number, constraints: { number: /[1-9]\d*/ } do
      get :action_plan, on: :member, path: "action-plan"
    end
    get "evaluate" => "evaluations#new", as: :new_evaluation
    get "evaluate/action-plan" => "evaluations#preview", as: :evaluation_preview
  end
  get "standards" => "standards#index"

  root "restaurants#index"
end
