require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:onbase_document) do
      add_column(:filename, String, :null => true)
      add_column(:mime_type, String, :null => true)
    end
  end

  down do
  end

end
