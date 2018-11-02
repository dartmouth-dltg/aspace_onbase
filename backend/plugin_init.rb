Permission.define("manage_onbase_record",
                  "The ability to create and unlink onbase records",
                  :level => "repository")


require_relative "../lib/document_keyword_definitions"
require_relative "../lib/keyword_name_mapper"
require_relative "../lib/file_buffer"

KeywordNameMapper.configure_i18n


# Hit these early just to make sure they're set
settings = [:onbase_robi_url, :onbase_robi_username, :onbase_robi_password_secret,
            :onbase_keyword_job_interval_seconds,
            :onbase_delete_unlinked_documents_cron,
            :onbase_delete_obsolete_documents_cron]
begin
  settings.each do |setting|
    AppConfig[setting]
  end
rescue
  msg = "You need to set the following config.rb settings: #{settings.inspect}"
  Log.error(msg)
  raise msg
end


# Make sure all required keyword generators are defined
missing = []
DocumentKeywordDefinitions::DOCUMENT_TYPE_DEFINITIONS.each do |type, definition|
  generator = DocumentKeywordsGenerator.new

  definition[:fields].each do |field|
    if field.fetch(:type) == 'generated'
      begin
        generator.generator_for(field.fetch(:generator))
      rescue
        missing << {:document_type => type, :generator => field.fetch(:generator), :exception => $!}
      end
    end
  end
end

if !missing.empty?
  msg = "Missing a keyword generator for the following:\n\n"
  missing.each do |missing|
    msg += "  * Document type #{missing[:document_type]}, field generator #{missing[:generator]} (#{missing[:exception]})\n"
  end
  msg += "\n\n"
  msg += "Generators are defined in DocumentKeywordsGenerator::GENERATORS\n"


  Log.error(msg)
  raise msg
end



ArchivesSpaceService.settings.scheduler.every("#{AppConfig[:onbase_keyword_job_interval_seconds]}s", :allow_overlapping => false) do
  OnbaseKeywordJob.process_jobs
end


ArchivesSpaceService.settings.scheduler.cron(AppConfig[:onbase_delete_unlinked_documents_cron], :allow_overlapping => false) do
  Repository.each do |repo|
    RequestContext.open(:current_username => "admin",
                        :repo_id => repo.id) do
      OnbaseDocument.delete_unlinked_documents
    end
  end
end

ArchivesSpaceService.settings.scheduler.cron(AppConfig[:onbase_delete_obsolete_documents_cron], :allow_overlapping => false) do
  Repository.each do |repo|
    RequestContext.open(:current_username => "admin",
                        :repo_id => repo.id) do
      OnbaseDocument.delete_obsolete_documents
    end
  end
end
