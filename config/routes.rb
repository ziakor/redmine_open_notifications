Rails.application.routes.draw do
  resources :user_notifications, only: [:index, :update, :destroy] do
    collection do
      post :read_all
      post :clear_all
    end
    member do
      post :snooze
    end
  end
  resource :notification_preference, only: [:show, :edit, :update]
end
