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

  get 'scraper', to: 'scraper#index'

  get 'scraper_companies', to: 'scraper#companies'
  get 'scraper_one_company', to: 'scraper#one_company'

  get 'scraper_people', to: 'scraper#people'
  get 'scraper_one_person', to: 'scraper#one_person'

  get 'scraper_one_job', to: 'scraper#one_job'
  get 'scraper_list_jobs', to: 'scraper#list_jobs'
  get 'scraper_set_authorization', to: 'scraper#set_authorization'

  get 'scraper_testing', to: 'scraper#testing'

end
