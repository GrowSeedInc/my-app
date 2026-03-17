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
    resources :users do
      collection do
        get  :export_csv
        get  :import_template
        post :import_csv
      end
    end
    resources :category_majors do
      collection do
        get  :export_csv
        get  :import_template
        post :import_csv
      end
    end
    resources :category_mediums do
      collection do
        get :by_major
      end
    end
    resources :category_minors do
      collection do
        get :by_medium
      end
    end
    resources :loans, only: [ :new, :create ] do
      collection do
        get  :import_template
        post :import_csv
      end
    end
  end

  resource :mypage, only: :show

  resources :equipments do
    collection do
      get  :export_csv
      get  :import_template
      post :import_csv
    end
  end
  resources :loans, only: [ :index, :new, :create ] do
    collection do
      get :export_csv
    end
    member do
      patch :approve
      patch "return", action: :return_loan, as: :return
    end
  end

  get  "/setup", to: "setups#new",    as: :setup
  post "/setup", to: "setups#create"

  # Defines the root path route ("/")
  root "equipments#index"
end
