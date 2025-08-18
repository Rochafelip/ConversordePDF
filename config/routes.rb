Rails.application.routes.draw do
  get 'pdfs/new'
  get 'pdfs/create'
  get 'pdfs/show'

  resources :pdfs, only: [:new, :create, :show]

  get "up" => "rails/health#show", as: :rails_health_check

  root 'pdfs#new'
end
