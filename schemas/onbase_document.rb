{
  :schema => {
    "$schema" => "http://www.archivesspace.org/archivesspace.json",
    "version" => 1,
    "type" => "object",
    "uri" => "/repositories/:repo_id/onbase_documents",
    "properties" => {
      "uri" => {"type" => "string", "required" => false},
      "onbase_id" => {"type" => "string", "maxLength" => 255, "ifmissing" => "error"},
      "document_type" => {"type" => "string", "ifmissing" => "error"},
      "keywords" => {"type" => "string"},
      "display_string" => {"type" => "string", "readonly" => "true"},
      "filename" => {"type" => "string"},
      "mime_type" => {"type" => "string"},
      "linked_record" => {
        "type" => "object",
        "subtype" => "ref",
        "readonly" => "true",
        "properties" => {
          "ref" => {
            "type" => [{"type" => "JSONModel(:accession) uri"},
                       {"type" => "JSONModel(:event) uri"},
                       {"type" => "JSONModel(:resource) uri"},
                       {"type" => "JSONModel(:archival_object) uri"},
                       {"type" => "JSONModel(:digital_object) uri"},
                       {"type" => "JSONModel(:digital_object_component) uri"},
                       {"type" => "JSONModel(:subject) uri"},
                       {"type" => "JSONModel(:agent_family) uri"},
                       {"type" => "JSONModel(:agent_corporate_entity) uri"},
                       {"type" => "JSONModel(:agent_person) uri"},
                       {"type" => "JSONModel(:agent_software) uri"}],
            "ifmissing" => "error"
          },
          "_resolved" => {
            "type" => "object",
            "readonly" => "true"
          }
        }
      },
      "deletion_pending" => {"type" => "boolean", "readonly" => "true", "default" => false},
      "new_and_unlinked" => {"type" => "boolean", "readonly" => "true", "default" => true}
    },
  },
}
