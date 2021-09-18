Rails.application.routes.draw do
  resources :route_sets
  resources :routes
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root "welcome#index"
  get '/climb', to: 'welcome#climb', as: 'climb'
  get '/edit-route-sets', to: 'welcome#edit_route_sets', as: 'edit_route_sets'
  get '/add-route-set', to: 'welcome#add_route_set', as: 'add_route_set'
  post '/add-route-set', to: 'welcome#add_route_set_save'
end
