Rails.application.routes.draw do
  root "dashboard#index"
  get "catalog", to: "catalog#index"

  resources :articles do
    collection { get :lookup }
  end

  resources :transfers, only: [ :index, :new, :create ]

  resources :brands, only: [ :index, :new, :create ] do
    collection do
      get  :list
      post :create_modal
    end
    member do
      patch  :update
      delete :destroy
    end
  end

  resources :models, only: [ :index, :new, :create ] do
    collection do
      get  :for_brand
      post :create_modal
    end
    member do
      patch  :update
      delete :destroy
    end
  end

  resources :people do
    collection do
      get  :lookup
      post :create_modal
    end
  end

  resource  :session

  resources :passwords, param: :token

  namespace :api do
    namespace :v1 do
      resources :people, except: [ :new, :edit ] do
        member { get :articles }
      end
      resources :articles,  except: [ :new, :edit ]
      resources :transfers, except: [ :new, :edit ]
      resources :brands,    except: [ :new, :edit ]
      resources :models,    except: [ :new, :edit ]
    end
  end

  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
end
