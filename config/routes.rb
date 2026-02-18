Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: 'users/sessions' }
  resource :two_factor_setting, only: %i[new create destroy], controller: 'users/two_factor_settings'
  resource :two_factor_verification, only: %i[new create], controller: 'users/two_factor_verifications'
  root 'memos#index'
  resources :memos, only: [:index]
  get 'up' => 'rails/health#show', as: :rails_health_check
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?
end
