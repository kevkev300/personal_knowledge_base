Rails.application.routes.draw do
  root 'notebooks#index'

  resources :notebooks
  resources :notes
  resources :notes_tags
  resources :tags
end
