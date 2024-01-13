Rails.application.routes.draw do
  # get 'analytic/index'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "home#index"

  get 'analytic', to: 'analytic#index'
  get 'categories', to: 'categories#index'
  get 'categories_inline', to: 'categories#categories_inline'
  get 'testing_data', to: 'testing_data#index'
  get 'api_chat', to: 'api_chat#index'

end
