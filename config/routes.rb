Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "paths#index"
  get "about" => "pages#about"
  get "roadmap" => "pages#roadmap"
  get "support_us" => "pages#support_us"
  get "robots.txt" => "sitemaps#robots", defaults: { format: :text }
  get "sitemap.xml" => "sitemaps#show", defaults: { format: :xml }

  resource :account, only: [ :show, :update ], controller: "account"
  patch "account/password", to: "account#update_password", as: :account_password
  scope module: :account_settings, path: "account", as: :account do
    resource :email, only: [ :edit, :create ]
    resource :email_verification, only: [ :new, :create ]
    resource :deletion, only: [ :new, :create ]
  end

  resource :session, only: [ :new, :create, :destroy ]
  resource :signup, only: [ :new, :create ], controller: "signups"
  scope module: :signups, path: "signup", as: :signup do
    resource :verification, only: [ :new, :create ]
    resource :completion, only: [ :new, :create ]
  end
  resources :passwords, param: :token, only: [ :new, :create, :edit, :update ]
  # Reminder-email opt-out (link + RFC 8058 one-click POST from mail clients).
  get "unsubscribe/:token" => "unsubscribes#show", as: :unsubscribe
  post "unsubscribe/:token" => "unsubscribes#create"
  get "dashboard" => "dashboard#show"
  resource :learning_goal, only: [ :edit, :update ]
  get "projects" => "projects#index"
  resources :journal_entries, path: "journal", except: [ :show ]
  resources :feedbacks, only: [ :new, :create ]

  resources :paths, only: [ :index, :show ], param: :slug
  resources :courses, only: [ :show ], param: :slug
  resources :lessons, only: [ :show ], param: :slug do
    resource :completion, only: [ :create, :destroy ], controller: "lesson_completions"
    resource :bookmark, only: [ :create, :destroy ], controller: "lesson_bookmarks"
    resources :revisions, only: [ :index, :show ]
    resources :suggestions, only: [ :new, :create ], controller: "lesson_suggestions"
  end

  namespace :admin do
    root "dashboard#show"
    resources :lessons, only: [ :index, :edit, :update ], param: :slug do
      resources :revisions, only: [ :index ] do
        member { post :rollback }
      end
    end
    resources :paths, only: [ :index, :edit, :update ], param: :slug
    resources :courses, only: [ :index, :edit, :update ], param: :slug
    resources :users, only: [ :index, :update ]
    resources :feedbacks, only: [ :index ]
    resources :lesson_suggestions, only: [ :index, :show ] do
      member do
        patch :approve
        patch :reject
      end
    end
    post "preview", to: "preview#create"
  end
end
