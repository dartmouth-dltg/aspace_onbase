require 'db/migrations/utils'

Sequel.migration do

  up do
    alter_table(:onbase_document) do
      add_column(:repo_id, Integer, :null => false, :default => 2) # FIXME: don't default to 2!
      add_foreign_key([:repo_id], :repository, :key => :id)
    end

    self[:onbase_document].update(:system_mtime => Time.now)
  end

  down do
  end

end
