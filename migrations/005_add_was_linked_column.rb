require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:onbase_document) do
      add_column(:was_linked, Integer, :null => false, :default => 0)
    end
  end

end
