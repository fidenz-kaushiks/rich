Rich::Engine.routes.draw do

  resources :files, :controller => "files"
  resources :storage_folder, :controller => "files"

  get 'files/parents/:parent_id' => 'files#parent_list'
end
