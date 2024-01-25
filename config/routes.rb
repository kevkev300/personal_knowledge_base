Rails.application.routes.draw do
  root 'tags#index'

  resources :notebooks
  resources :notes
  resources :tags
end
