Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  namespace :api do
    namespace :v1, format: :json do
      resources :authentication, only: [:create]
      resources :users, only: [:create]
      resources :games, only: [:index, :create]
      resources :analytics, only: [:index, :create]
      get '/find_game', to: 'games#join_game'
      post '/machine_vs_machine', to: 'games#machine_vs_machine'
    end
  end
end
