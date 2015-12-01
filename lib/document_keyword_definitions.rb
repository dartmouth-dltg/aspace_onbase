class DocumentKeywordDefinitions

  DOCUMENT_TYPE_DEFINITIONS = {
    "SPCL - Agent Correspondence" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :agent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier}
      ]},

    "SPCL - Deed" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :agent_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Transfer Receipt" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :agent_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Dealer Object Description" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :agent_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},
    
    "SPCL - Dealer Invoice" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :agent_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Processing Plan" => {
      :supported_records => [:accession, :resource, :event],
      :fields => [
        {:type => "enum_catalog_location", :keyword => :catalog_location_keyword},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :event_processing_plan_date},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :record_identifier},
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :agent_system_id},
      ]},

    "SPCL - Accession Snapshot" => {
      :supported_records => [:accession, :archival_object],
      :fields => [
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :accession_date},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Preservation Photo" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "text", :keyword => :conservation_number_keyword},
        {:type => "enum_catalog_location", :keyword => :catalog_location_keyword},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Preservation Documentation" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "text", :keyword => :conservation_number_keyword},
        {:type => "enum_catalog_location", :keyword => :catalog_location_keyword},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Missing Items Record" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Oral History Release Form" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Deaccession Record" => {
      :supported_records => [:accession, :archival_object, :event],
      :fields => [
        {:type => "enum_catalog_location", :keyword => :catalog_location_keyword},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Patron Registration Form" => {
      :supported_records => [:event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
      ]},

    "SPCL - Permission to Publish Form" => {
      :supported_records => [:archival_object, :event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Loan Agreement" => {
      :supported_records => [:event],
      :fields => [
        {:type => "date", :keyword => :loan_end_date_keyword},
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
      ]},

    "SPCL - Facilities Report" => {
      :supported_records => [:event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
      ]},

    "SPCL - Insurance Valuation" => {
      :supported_records => [:event],
      :fields => [
        {:type => "generated", :generator => :agent_name},
        {:type => "generated", :generator => :parent_system_id},
      ]},
    
    "SPCL - Superseded Finding Aids" => {
      :supported_records => [:archival_object],
      :fields => [
        {:type => "text", :keyword => :finding_aid_use_start_date_keyword},
        {:type => "date", :keyword => :finding_aid_use_end_date_keyword},
        {:type => "generated", :generator => :parent_system_id},
        {:type => "generated", :generator => :linked_record_system_id},
        {:type => "generated", :generator => :record_identifier},
      ]},

    "SPCL - Example Document Type" => {
      :supported_records => [:event, :accession],
      :fields => [
        {:type => "text", :keyword => :example_alpha_20_keyword},
        {:type => "date", :keyword => :example_date_keyword},
        {:type => "generated", :generator => :example_alpha_250_keyword}
      ]
    }
  }

  def document_types_for_record(record_type)
    DOCUMENT_TYPE_DEFINITIONS.select {|doctype, definition | definition[:supported_records].include?(record_type)}
  end

  def definitions_for_document_type(document_type)
    DOCUMENT_TYPE_DEFINITIONS.fetch(document_type)[:fields]
  end

end
