OSMExtender::Application.routes.draw do

  get 'welcome/index'
  get 'my_page' => 'my_page#index', :as => 'my_page'

  get 'signin' => 'sessions#new', :as => 'signin'
  get 'signout' => 'sessions#destroy', :as => 'signout'
  get 'signup(/:signup_code)' => 'users#new', :as => 'signup'
  
  get 'my_account' => 'my_account#show', :as => 'my_account'
  get 'my_account/change_password' => 'my_account#change_password', :as => 'change_my_password'
  put 'my_account/update_password' => 'my_account#update_password', :as => 'update_my_password'
  get 'my_account/edit' => 'my_account#edit', :as => 'edit_my_account'
  put 'my_account/update' => 'my_account#update', :as => 'update_my_account'
  get 'my_account/connect_to_osm' => 'my_account#connect_to_osm', :as => 'connect_to_osm'
  post 'my_account/connect_to_osm' => 'my_account#connect_to_osm2', :as => 'connect_to_osm2'

  get 'osm_permissions' => 'osm_permissions#view', :as => 'osm_permissions'

  get 'email_lists/generate' => 'email_lists#generate', :as => 'generate_email_list'
  post 'email_lists/generate' => 'email_lists#generate2', :as => 'generate_email_list2'

  match 'activate_account/:token' => 'users#activate_account', :as => 'activate_account'
  match 'reset_password/:token' => 'password_resets#edit', :as => 'reset_password'

  resources :users
  get 'users/:id/reset_password' => 'users#reset_password', :as => 'reset_password_user'
  get 'users/:id/resend_activation' => 'users#resend_activation', :as => 'resend_activation_user'

  resources :sessions
  get 'session/change_section' => 'sessions#change_section', :as => 'change_section'

  resources :faqs
  get 'help' => 'faqs#list', :as => 'list_faqs'

  get 'programme_review/balanced' => 'programme_review#balanced', :as => 'programme_review_balanced'
  get 'programme_review/balanced_data' => 'programme_review#balanced_data', :as => 'programme_review_balanced_data'

  delete 'programme_review_balanced_cache/:id(.:format)' => 'programme_review_balanced_cache#destroy', :as => 'programme_review_balanced_cach'

  resources :password_resets
  resources :contact_us, :only=>[:new, :create]
  resources :email_reminders do
    resources :email_reminder_items, :as => 'items'
    resources :email_reminder_item_birthdays, :as => 'item_birthdays'
    resources :email_reminder_item_due_badges, :as => 'item_due_badges'
    resources :email_reminder_item_events, :as => 'item_events'
    resources :email_reminder_item_not_seens, :as => 'item_not_seens'
    resources :email_reminder_item_programmes, :as => 'item_programmes'
  end

  root :to => 'welcome#index'
end
