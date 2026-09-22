Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # First in file — must win over every route below.
  constraints(host: "www.#{URI(Rails.application.config.x.site.url).host}") do
    match "(*path)", via: :all, to: redirect(status: 301) { |_params, request|
      "#{Rails.application.config.x.site.url}#{request.fullpath}"
    }
  end

  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker, defaults: { format: :js }

  get "robots.txt" => "sitemaps#robots", defaults: { format: :text }
  get "sitemap.xml" => "sitemaps#show", defaults: { format: :xml }

  if (indexnow_key = ENV["INDEXNOW_KEY"]).present?
    get "#{indexnow_key}.txt",
        to: ->(_env) { [ 200, { "Content-Type" => "text/plain" }, [ indexnow_key ] ] }
  end

  # Optional here but canonical in practice — ApplicationController 301s unprefixed GETs.
  get "/", to: redirect("/#{I18n.default_locale}", status: 301)

  scope "(:locale)", locale: Regexp.new(I18n.available_locales.join("|")) do
    root "paths#index"
    get "about" => "pages#about"
    get "contribute" => "pages#contribute"
    get "authors" => "pages#authors"
    get "faq" => "pages#faq"
    get "guide" => "pages#guide"
    get "partners" => "pages#partners"
    get "roadmap" => "pages#roadmap"
    get "support_us" => "pages#support_us"
    get "privacy" => "pages#privacy"

    resource :account, only: [ :show, :update ], controller: "account"
    patch "account/password", to: "account#update_password", as: :account_password
    scope module: :account_settings, path: "account", as: :account do
      resource :email, only: [ :edit, :create ]
      resource :email_verification, only: [ :new, :create ]
      resource :deletion, only: [ :new, :create ]
      resource :photo, only: [ :create, :destroy ]
    end

    resource :session, only: [ :new, :create, :destroy ]
    resource :signup, only: [ :new, :create ], controller: "signups"
    scope module: :signups, path: "signup", as: :signup do
      resource :verification, only: [ :new, :create ]
      resource :completion, only: [ :new, :create ]
    end
    resources :passwords, param: :token, only: [ :new, :create, :edit, :update ]
    # RFC 8058 one-click unsubscribe: mail clients POST this without a confirm page.
    get "unsubscribe/:token" => "unsubscribes#show", as: :unsubscribe
    post "unsubscribe/:token" => "unsubscribes#create"
    get "dashboard" => "dashboard#show"
    resource :search, only: [ :show ]
    resource :learning_goal, only: [ :edit, :update ]
    get "projects" => "projects#index"
    get "resources" => "resources#index"
    get "calculators/power-current", to: redirect("/calculators/cable-cross-section", status: 301)
    resources :calculators, only: [ :index, :show ], param: :slug
    resource :glossary, only: [ :show ], controller: "glossaries"
    resources :journal_entries, path: "journal", except: [ :show ]
    resource :map, only: [ :create, :edit, :update, :destroy ]
    resources :profiles, path: "u", param: :handle, only: :show do
      scope module: :profiles do
        resource :map, only: :show do
          resource :follow, only: [ :create, :destroy ]
        end
      end
    end
    resources :feedbacks, only: [ :new, :create ]
    resource :coauthor_application, only: [ :new, :create ]
    resource :editor_welcome, only: [ :destroy ]
    get "business" => "business_inquiries#new", as: :business
    post "business" => "business_inquiries#create"

    resources :posts, path: "news", only: [ :index, :show ], param: :slug do
      resource :reaction, only: [ :create, :destroy ]
    end

    resources :paths, only: [ :index, :show ], param: :slug do
      scope module: :paths do
        resource :theory, only: :show
        resource :practice, only: :show
        resource :glossary, only: :show
        resource :library, only: :show
      end
    end
    resources :courses, only: [ :show ], param: :slug
    resources :lessons, only: [ :show ], param: :slug do
      resource :completion, only: [ :create, :destroy ], controller: "lesson_completions"
      resource :bookmark, only: [ :create, :destroy ], controller: "lesson_bookmarks"
      resources :revisions, only: [ :index, :show ]
      resources :suggestions, only: [ :new, :create ], controller: "lesson_suggestions"
      resources :resource_suggestions, only: [ :new, :create ]
    end

    namespace :admin do
      root "dashboard#show"
      get "dashboard/vitals" => "dashboard#vitals", as: :dashboard_vitals
      resources :lessons, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug do
        resources :revisions, only: [ :index ] do
          member { post :rollback }
        end
        resources :illustrations, only: [ :new, :create ]
      end
      # Nested under the profession — path slug rides in the URL, cleaner auth than a body param.
      resources :paths, only: [ :index, :new, :create, :show, :edit, :update, :destroy ], param: :slug do
        scope module: :paths do
          resources :lesson_moves, only: :create
          resources :course_moves, only: :create
          resources :lesson_names, only: :update
          resources :course_names, only: :update
          resource  :stage_rename, only: :update
          resource  :verification, only: [ :create, :destroy ]
          resource  :export, only: :show
          resources :editorships, only: [ :create, :destroy ]
        end
      end
      resources :courses, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug
      resources :posts, path: "news", only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug
      resources :imports, only: [ :new, :create ]
      get "guide", to: redirect("/guide")
      resources :users, only: [ :index, :show, :update ] do
        resource :suspension, only: [ :create, :destroy ]
        resource :photo, only: :destroy
      end
      resources :feedbacks, only: [ :index ] do
        resource :coauthor_approval, only: :create
      end
      get "log" => "admin_actions#index", as: :log
      resources :lesson_suggestions, only: [ :index, :show ] do
        member do
          patch :approve
          patch :reject
        end
      end
      resources :resource_suggestions, only: [ :index ] do
        member do
          patch :approve
          patch :reject
        end
      end
      resources :illustrations, only: :index
      resources :lesson_links, only: :index

      post "preview", to: "preview#create"
      # Gated, validating replacement for the open ActiveStorage direct-upload endpoint.
      resources :uploads, only: :create
    end
  end
end
