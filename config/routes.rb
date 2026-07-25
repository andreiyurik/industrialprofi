Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Installable PWA: dynamic manifest + service worker from app/views/pwa/*.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest, defaults: { format: :json }
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker, defaults: { format: :js }

  root "paths#index"
  get "about" => "pages#about"
  get "contribute" => "pages#contribute"
  # The recruitment landing for practitioners — what a master gets by leading a
  # profession; funnels into the co-author application.
  get "authors" => "pages#authors"
  get "faq" => "pages#faq"
  # The author's reference — public like the content itself: readers suggesting
  # an edit and editors reviewing one read the SAME rules.
  get "guide" => "pages#guide"
  get "partners" => "pages#partners"
  get "roadmap" => "pages#roadmap"
  get "support_us" => "pages#support_us"
  get "privacy" => "pages#privacy"
  get "robots.txt" => "sitemaps#robots", defaults: { format: :text }
  get "sitemap.xml" => "sitemaps#show", defaults: { format: :xml }

  # IndexNow ownership proof: serve the key as plain text at /<key>.txt. Only
  # mounted when a key is configured (the key IS the route — no controller needed).
  if (indexnow_key = ENV["INDEXNOW_KEY"]).present?
    get "#{indexnow_key}.txt",
        to: ->(_env) { [ 200, { "Content-Type" => "text/plain" }, [ indexnow_key ] ] }
  end

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
  resource :search, only: [ :show ]
  resource :learning_goal, only: [ :edit, :update ]
  get "projects" => "projects#index"
  get "resources" => "resources#index"
  resources :calculators, only: [ :index, :show ], param: :slug
  # Professional abbreviations decoded — a static reference page (see Glossary).
  resource :glossary, only: [ :show ], controller: "glossaries"
  resources :journal_entries, path: "journal", except: [ :show ]
  resources :feedbacks, only: [ :new, :create ]
  # Expert-entry gate (loop #1): a structured "become a co-author" application.
  # Stored as a tagged Feedback for now — no separate model until volume warrants
  # tracking application status.
  resource :coauthor_application, only: [ :new, :create ]
  # Acknowledging the founder's one-shot letter to a newly promoted editor.
  resource :editor_welcome, only: [ :destroy ]
  # B2B demand sensor: the pitch page for training centers/employers + their
  # inquiry form (also a tagged Feedback). GET shows the page, POST sends.
  get "business" => "business_inquiries#new", as: :business
  post "business" => "business_inquiries#create"

  # News — the founder's «проект живёт» channel. Read-only public pages under
  # /news; the one engagement affordance is a ❤️ (no comments, zero moderation).
  resources :posts, path: "news", only: [ :index, :show ], param: :slug do
    resource :reaction, only: [ :create, :destroy ]
  end

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
    get "dashboard/vitals" => "dashboard#vitals", as: :dashboard_vitals
    resources :lessons, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug do
      resources :revisions, only: [ :index ] do
        member { post :rollback }
      end
    end
    # paths#show is the curriculum builder (the tree); #index is its landing.
    # Builder mutations (reorder, rename) are nested RESTful resources scoped to
    # the profession, so the path slug rides in the URL (cleaner auth than a body
    # param). The work itself lives in Path::Curriculum.
    resources :paths, only: [ :index, :new, :create, :show, :edit, :update, :destroy ], param: :slug do
      scope module: :paths do
        resources :lesson_moves, only: :create
        resources :course_moves, only: :create
        resources :lesson_names, only: :update
        resources :course_names, only: :update
        resource  :stage_rename, only: :update
        # The curator's hand-set «проверено экспертом» mark (see Path::Maturity).
        resource  :verification, only: [ :create, :destroy ]
      end
    end
    resources :courses, only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug
    resources :posts, path: "news", only: [ :index, :new, :create, :edit, :update, :destroy ], param: :slug
    resources :imports, only: [ :new, :create ]
    # The guide went public (readers suggesting edits need it too) — old
    # editor bookmarks land on the new home.
    get "guide", to: redirect("/guide")
    resources :users, only: [ :index, :show, :update ] do
      resource :suspension, only: [ :create, :destroy ]
    end
    resources :feedbacks, only: [ :index ] do
      member { post :approve_coauthor }
    end
    get "log" => "admin_actions#index", as: :log
    resources :lesson_suggestions, only: [ :index, :show ] do
      member do
        patch :approve
        patch :reject
      end
    end
    # Content-health queue: every lesson image placeholder still waiting for a
    # real picture, with its illustrator brief and a link into the editor.
    resources :illustrations, only: :index

    post "preview", to: "preview#create"
    # Editor/admin-only image uploads for lesson rich text — a gated, validating
    # replacement for the open ActiveStorage direct-upload endpoint.
    resources :uploads, only: :create
  end
end
