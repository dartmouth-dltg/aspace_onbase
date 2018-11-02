require 'db/migrations/utils'

Sequel.migration do

  up do
    create_table(:onbase_document) do
      primary_key :id

      Integer :lock_version, :default => 0, :null => false
      Integer :json_schema_version, :null => false

      String :onbase_id, :null => false
      String :document_type, :null => false

      apply_mtime_columns
    end

    alter_table(:onbase_document) do
      add_unique_constraint(:onbase_id, :name => "onbase_id_uniq")
    end

    create_table(:onbase_document_rlshp) do
      primary_key :id
      Integer :onbase_document_id

      Integer :accession_id
      Integer :archival_object_id
      Integer :resource_id
      Integer :subject_id
      Integer :agent_person_id
      Integer :agent_family_id
      Integer :agent_corporate_entity_id
      Integer :agent_software_id
      Integer :rights_statement_id
      Integer :digital_object_id
      Integer :digital_object_component_id
      Integer :event_id

      Integer :aspace_relationship_position

      apply_mtime_columns(false)
    end

    alter_table(:onbase_document_rlshp) do
      add_foreign_key([:onbase_document_id], :onbase_document, :key => :id)
      add_foreign_key([:accession_id], :accession, :key => :id)
      add_foreign_key([:archival_object_id], :archival_object, :key => :id)
      add_foreign_key([:resource_id], :resource, :key => :id)
      add_foreign_key([:subject_id], :subject, :key => :id)
      add_foreign_key([:agent_person_id], :agent_person, :key => :id)
      add_foreign_key([:agent_family_id], :agent_family, :key => :id)
      add_foreign_key([:agent_corporate_entity_id], :agent_corporate_entity, :key => :id)
      add_foreign_key([:agent_software_id], :agent_software, :key => :id)
      add_foreign_key([:rights_statement_id], :rights_statement, :key => :id)
      add_foreign_key([:digital_object_id], :digital_object, :key => :id)
      add_foreign_key([:digital_object_component_id], :digital_object_component, :key => :id)
      add_foreign_key([:event_id], :event, :key => :id)
    end
  end

  down do
  end

end
