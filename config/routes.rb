Rails.application.routes.draw do
  resources :climbs do
    get "/share", to: "climb_share#show"
  end
  resources :route_sets
  resources :routes

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "welcome#index"
  get '/menu', to: 'menu#index'

  get '/auth/auth0/callback' => 'auth0#callback'
  get '/auth/failure' => 'auth0#failure'
  get '/auth/logout' => 'auth0#logout'
end
