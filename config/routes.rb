Rails.application.routes.draw do
  devise_for :users

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  namespace :admin do
    resource :dashboard, only: :show
    resources :users
  end

  resource :mypage, only: :show

  resources :equipments
  resources :loans, only: [ :index, :new, :create ] do
    member do
      patch :approve
      patch "return", action: :return_loan, as: :return
    end
  end

  # Defines the root path route ("/")
  root "equipments#index"
end
