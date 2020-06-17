Rich::Engine.routes.draw do

  resources :files, :controller => "files"
  resources :storage_folder, :controller => "files"
end
