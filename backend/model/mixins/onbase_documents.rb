module OnbaseDocuments

  def self.included(base)
    base.include(Relationships)
    base.extend(ClassMethods)

    base.define_relationship(:name => :onbase_document,
                             :json_property => 'onbase_documents',
                             :contains_references_to_types => proc {[OnbaseDocument]})

  end

  ArchivesSpaceService.loaded_hook do
    # Define a reciprocal relationship for everything that we got linked to
    OnbaseDocument.define_relationship(:name => :onbase_document,
                                       :contains_references_to_types => proc {OnbaseDocument.relationship_dependencies[:onbase_document]})
  end


  def update_from_json(json, extra_values = {}, apply_nested_records = true)
    obj = super
    self.class.handle_onbase(json, obj)
    obj
  end


  module ClassMethods

    def handle_onbase(json, obj)
      if !Array(json.onbase_documents).empty?
        generator = DocumentKeywordsGenerator.new
        created_record = URIResolver.resolve_references(self.to_jsonmodel(obj), generator.get_resolved_types, {})

        onbase_ids = []

        Array(json.onbase_documents).each do |onbase_ref|
          ref = JSONModel.parse_reference(onbase_ref['ref'])

          next unless ref[:type] == 'onbase_document'
          onbase_ids << ref[:id]
          onbase_document = OnbaseDocument.to_jsonmodel(ref[:id])

          keywords = generator.keywords_for(created_record, onbase_document)

          # Create a pending job for setting keywords and run it immediately
          OnbaseKeywordJob.create(onbase_document, keywords, RequestContext.get(:current_username))
        end

        # All of the OnBase documents have now been linked to a record.  Mark
        # them as such so they can be cleaned up later if ever unlinked.
        unless onbase_ids.empty?
          OnbaseDocument.filter(:id => onbase_ids).update(:was_linked => 1)
        end
      end

      obj
    end

    def create_from_json(json, opts = {})
      obj = super
      handle_onbase(json, obj)
      obj
    end
  end

end
