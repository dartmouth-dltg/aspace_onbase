ArchivesSpace::Application.extend_aspace_routes(File.join(File.dirname(__FILE__), "routes.rb"))

require_relative "../lib/document_keyword_definitions"
require_relative "../lib/file_buffer"
require_relative "../lib/keyword_name_mapper"


Rails.application.config.after_initialize do

  KeywordNameMapper.configure_i18n

  ActionView::PartialRenderer.class_eval do
    alias_method :render_pre_aspace_onbase, :render
    def render(context, options, block)
      result = render_pre_aspace_onbase(context, options, block);

      result
    end
  end


  ApplicationController.class_eval do

    alias_method :find_opts_pre_aspace_onbase, :find_opts

    def find_opts
      orig = find_opts_pre_aspace_onbase
      orig.merge('resolve[]' => orig['resolve[]'] + ['onbase_documents'])
    end

  end


  SearchHelper.class_eval do

    alias_method :can_edit_search_result_pre_aspace_onbase?, :can_edit_search_result?

    def can_edit_search_result?(record)
      return false if record['primary_type'] === "onbase_document"
      can_edit_search_result_pre_aspace_onbase?(record)
    end

  end


  SearchResultData.class_eval do
    alias_method :facet_label_string_pre_aspace_onbase, :facet_label_string
    def facet_label_string(facet_group, facet)
      if ["linked_to_record_u_ubool", "deletion_pending_u_ubool", "new_and_unlinked_u_ubool"].include?(facet_group)
        return I18n.t("search_results.filter_terms.#{facet_group}.#{facet.to_s}", :default => facet.to_s)
      end

      facet_label_string_pre_aspace_onbase(facet_group, facet)
    end
  end


  # force load our JSONModels so the are registered rather than lazy initialised
  # we need this for parse_reference to work
  JSONModel(:onbase_document)

end
