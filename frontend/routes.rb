ArchivesSpace::Application.routes.draw do
  match('/plugins/onbase_documents/keywords_form' => 'onbase_documents#keywords_form', :via => [:post])
  match('/plugins/onbase_documents/upload' => 'onbase_documents#upload', :via => [:post])
  resources :onbase_document
  match('/plugins/onbase_documents/:id/download' => 'onbase_documents#download', :via => [:get])
  match('/plugins/onbase_documents/:id/keywords' => 'onbase_documents#keywords', :via => [:get])
  match('/plugins/onbase_documents/:id/unlink' => 'onbase_documents#unlink', :via => [:post])
end
