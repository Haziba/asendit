Rails.application.routes.draw do
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
end
