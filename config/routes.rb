Rails.application.routes.draw do
  # Health check endpoint for deployment
  get '/health', to: 'health#index'

  # API routes for React Native app
  namespace :api do
    namespace :v1 do
      get 'climbs/current', to: 'climbs#current'
      resources :climbs do
        post 'complete', on: :member
      end
      resources :routes, only: [:index, :show, :create, :destroy]
      resources :places do
        post 'choose', on: :member
        resources :grades, only: [:index, :show, :create, :update, :destroy] do
          resources :route_sets, only: [:index, :show, :create, :update, :destroy]
        end
        resources :floorplans do
          patch 'update_data', on: :member
          post 'upload_image', on: :member
        end
      end
      # Non-nested routes for grades, route_sets, and floorplans (convenience aliases)
      resources :grades, only: [:show, :update, :destroy] do
        resources :route_sets, only: [:index, :show, :create, :update, :destroy]
      end
      resources :route_sets, only: [:show, :update, :destroy]
      resources :floorplans, only: [:show, :update, :destroy] do
        patch 'update_data', on: :member
        post 'upload_image', on: :member
      end
      resources :tournaments do
        patch 'update_routes', on: :member
      end
      resource :user, only: [:show]
    end
  end

  get "climbs/current", to: "climbs#current"
  resources :climbs do
    get "/share", to: "climb_share#show"
    post "/complete", to: "climbs#complete"
  end

  resources :route_sets, except: [:new, :create]
  resources :routes

  resources :places do
    post '/choose', to: 'places#choose'
    resources :grades

    resources :tournaments do
      patch :update_routes, constraints: { format: :json }
    end

    resources :floorplans do
      patch :update_data, constraints: { format: :json }
      patch :upload_file, constraints: { format: :json }
    end

    resources :route_sets do
      member do
        patch :update, constraints: { format: :json }
      end
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "welcome#index"
  get '/menu', to: 'menu#index'

  get '/auth/auth0/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'
  get '/auth/logout' => 'auth0#logout'
  
  # Development-only route to bypass OAuth
  get '/dev_login' => 'auth0#dev_login' if Rails.env.development?
end
