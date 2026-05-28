Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "paths#index"
  get "support_us" => "pages#support_us"
  get "robots.txt" => "sitemaps#robots", defaults: { format: :text }
  get "sitemap.xml" => "sitemaps#show", defaults: { format: :xml }

  resources :paths, only: [ :index, :show ], param: :slug
  resources :lessons, only: [ :show ], param: :slug do
    resources :revisions, only: [ :index, :show ]
  end
  resources :lesson_suggestions, only: [ :new, :create ]

  namespace :admin do
    resources :lessons, only: [ :index, :edit, :update ], param: :slug do
      resources :revisions, only: [ :index ] do
        member { post :rollback }
      end
    end
    resources :paths, only: [ :index, :edit, :update ], param: :slug
    resources :lesson_suggestions, only: [ :index, :show ] do
      member do
        patch :approve
        patch :reject
      end
    end
    post "preview", to: "preview#create"
  end
end
