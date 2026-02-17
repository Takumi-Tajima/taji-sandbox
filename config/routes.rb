Rails.application.routes.draw do
  devise_for :users
  root 'memos#index'
  resources :memos, only: [:index]
  get 'up' => 'rails/health#show', as: :rails_health_check
end
