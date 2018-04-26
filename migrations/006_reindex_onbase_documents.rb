require 'db/migrations/utils'

Sequel.migration do

  up do
    self[:onbase_document].update(:system_mtime => Time.now)
  end

end