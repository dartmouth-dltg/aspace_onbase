class OnbaseDocumentsController < ApplicationController

  set_access_control  "view_repository" => [:index, :show, :download, :keywords],
                      "manage_onbase_record" => [:new, :create, :keywords_form, :unlink]


  SEARCH_FACETS = ["document_type_u_ustr", "mime_type_u_ustr", "linked_to_record_u_ubool", "deletion_pending_u_ubool", "new_and_unlinked_u_ubool"]


  def index
    @search_data = Search.for_type(session[:repo_id],
                                   "onbase_document",
                                   {"sort" => "title_sort asc"}.merge(params_for_backend_search.merge({"facet[]" => SEARCH_FACETS})))
  end

  def show
    @onbase_document = JSONModel(:onbase_document).find(params[:id], "resolve[]" => ["linked_record"])
  end

  def new
    @onbase_document = JSONModel(:onbase_document).new._always_valid!
    @parent_type = params[:parent_type].intern

    raise "Can only create an OnBase document from within the context of another record" if !inline?

    render_aspace_partial :partial => "onbase_documents/new"
  end

  def create
    file = params[:onbase_document][:file]
    keywords = params[:keywords] || {}
    document_type = params[:onbase_document][:document_type]

    errors = []

    errors << I18n.t("plugins.onbase_document._frontend.messages.file_required") if file.blank?

    if document_type.blank?
      errors << I18n.t("plugins.onbase_document._frontend.messages.document_type_required")
    else
      errors << validate_keywords(document_type, keywords)
    end

    errors.flatten!

    if !errors.empty?
      return render :json => errors, :status => 500
    end

    File.open(file.tempfile) do |fh|
      response = JSONModel::HTTP.post_form("/repositories/#{session[:repo_id]}/onbase_upload",
                                           {
                                             'file' => UploadIO.new(fh, file.content_type, file.original_filename),
                                             'document_type' => params[:onbase_document][:document_type],
                                             'keywords' => keywords.to_json
                                           },
                                           :multipart_form_data)

      json = ASUtils.json_parse(response.body)
      json['id'] = JSONModel(:onbase_document).id_for(json['uri'])

      render :json => json, :status => response.code
    end
  end


  def keywords_form
    definitions = DocumentKeywordDefinitions.new
    @doctype = params[:doctype]

    if @doctype.blank?
      return render :text => ""
    end

    @definition = definitions.definitions_for_document_type(@doctype)

    render_aspace_partial :partial => "onbase_documents/keywords_form"
  end


  def download
    queue = Queue.new

    backend_session = JSONModel::HTTP.current_backend_session

    Thread.new do
      JSONModel::HTTP.current_backend_session = backend_session

      begin
        JSONModel::HTTP::stream("/repositories/#{session[:repo_id]}/onbase_documents/#{params[:id]}/download") do |download_response|
          response.headers['Content-Disposition'] = download_response['Content-Disposition']
          response.headers['Content-Type'] = download_response['Content-Type']
          response.headers['Content-Length'] = download_response['Content-Length']
          queue << :ok
          download_response.read_body do |chunk|
            queue << chunk
          end
        end
      rescue
        queue << {:error => ASUtils.json_parse($!.message)}
      ensure
        queue << :EOF
      end

    end

    first_on_queue = queue.pop
    if first_on_queue.kind_of?(Hash)
      raise first_on_queue[:error]
    end

    self.response_body = Class.new do
      def self.queue=(queue)
        @queue = queue
      end
      def self.each(&block)
        while(true)
          elt = @queue.pop

          break if elt === :EOF
          block.call(elt)
        end
      end
    end

    self.response_body.queue = queue
  end


  def keywords
    keyword_json = JSONModel::HTTP::get_json("/repositories/#{session[:repo_id]}/onbase_documents/#{params[:id]}/keywords")
    @keywords = keyword_json['keywords']
    render :partial => "onbase_documents/keywords_readonly"
  end


  def unlink
    JSONModel::HTTP::post_form("/repositories/#{session[:repo_id]}/onbase_documents/#{params[:id]}/unlink")

    redirect_to(:controller => :onbase_documents, :action => :index)
  end


  private

  helper_method :onbase_document_doctype_options
  def onbase_document_doctype_options(record_type)
    definitions = DocumentKeywordDefinitions.new
    [""] + definitions.document_types_for_record(record_type).keys
  end


  def validate_keywords(doctype, keywords)
    errors = []

    definitions = DocumentKeywordDefinitions.new

    definitions.definitions_for_document_type(doctype).each do |field|
      if field[:type] != "generated"
        value = keywords[field[:keyword]]

        if value.blank?
          errors << I18n.t("plugins.onbase_document._frontend.messages.keyword_required", :code => I18n.t("plugins.onbase_document_keyword.#{field[:keyword]}"))
        end
      end
    end

    errors
  end

end
