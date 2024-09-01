Rails.application.routes.draw do
  get "climbs/current", to: "climbs#current"
  resources :climbs do
    get "/share", to: "climb_share#show"
    post "/complete", to: "climbs#complete"
  end

  resources :route_sets
  resources :routes
  resources :places do
    post '/choose', to: 'places#choose'
    resources :colour_sets do
      resources :colours, controller: 'colour_set_colours'
    end
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "welcome#index"
  get '/menu', to: 'menu#index'

  get '/auth/auth0/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'
  get '/auth/logout' => 'auth0#logout'
end
