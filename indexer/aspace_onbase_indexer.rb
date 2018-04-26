class IndexerCommon

  @@record_types << :onbase_document

  add_indexer_initialize_hook do |indexer|

    indexer.add_document_prepare_hook {|doc, record|
      if record['record']['jsonmodel_type'] == 'onbase_document'
        doc['title'] = record['record']['display_string']
        doc['document_type_u_ustr'] = record['record']['document_type']
        doc['mime_type_u_ustr'] = record['record']['mime_type']
        doc['linked_to_record_u_ubool'] = !!record['record']['linked_record']
        doc['deletion_pending_u_ubool'] = !!record['record']['deletion_pending']
        doc['new_and_unlinked_u_ubool'] = !!record['record']['new_and_unlinked']
      end
    }

  end

end
