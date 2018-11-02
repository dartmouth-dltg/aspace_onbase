class OnbaseDocument < Sequel::Model(:onbase_document)
  include ASModel
  include Relationships

  corresponds_to JSONModel(:onbase_document)

  set_model_scope :repository

  def display_string
    (deletion_pending? ? "[Deletion Pending] " : "") + "#{filename} - #{document_type} [#{onbase_id}] :: #{linked_record_display}"
  end


  def deletion_pending?
    linked_record_uri.nil? && was_linked == 1
  end


  def new_and_unlinked?
    linked_record_uri.nil? && was_linked == 0
  end


  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.zip(objs).each do |json, obj|
      json['display_string'] = obj.display_string
      json['deletion_pending'] = obj.deletion_pending?
      json['new_and_unlinked'] = obj.new_and_unlinked?
      json['linked_record'] = {
        'ref' => obj.linked_record_uri
      }
    end

    jsons
  end


  # Delete any document whose record in OnBase has vanished
  def self.delete_obsolete_documents
    Log.debug("AspaceOnbase Job: Delete Obsolete Documents (repo: #{self.active_repository})")
    client = OnbaseClient.new(:user => "ArchivesSpaceBackgroundTask")

    all_ids = OnbaseDocument.filter(:repo_id => self.active_repository).select(:id).map {|row| row[:id]}
    all_ids.each_slice(50) do |id_set|
      onbase_rows = OnbaseDocument.filter(:id => id_set).select(:id, :onbase_id).each do |row|
        begin
          rec = OnbaseDocument[row[:id]]
          next if !rec
          if !client.record_exists?(row[:onbase_id])
            puts "Deleting obsolete ArchivesSpace record: #{row[:id]}"
            rec.delete
          end
        rescue
          Log.error("Problem while checking record #{row[:onbase_id]}")
          Log.exception($!)
        end
      end
    end
  end


  # Delete any document that isn't connected to an ArchivesSpace record
  def self.delete_unlinked_documents
    Log.debug("AspaceOnbase Job: Delete Unlinked Documents (repo: #{self.active_repository})")
    client = OnbaseClient.new(:user => "ArchivesSpaceBackgroundTask")

    unlinked_ttl = if AppConfig.has_key?(:unlinked_onbase_document_ttl_seconds)
                     Integer(AppConfig[:unlinked_onbase_document_ttl_seconds])
                   else
                     24 * 60 * 60
                   end

    kill_time = Time.at(Time.now.to_i - unlinked_ttl)

    OnbaseDocument.left_outer_join(OnbaseDocument.find_relationship(:onbase_document),
                                   :onbase_document_id => :id).
      filter(:onbase_document_id => nil,
             :onbase_document__repo_id => self.active_repository).
      select(:onbase_document__id, :onbase_document__onbase_id).
      filter(:onbase_document__was_linked => 1).
      where { Sequel.qualify(:onbase_document, :system_mtime) <= kill_time }.each do |row|

      puts "Checking row: #{row.inspect}"
      Log.info("Deleting unlinked OnBase record #{row[:id]} (OnBase ID: #{row[:onbase_id]})")
      if client.delete(row[:onbase_id])
        Log.info("Deleting corresponding OnBase document #{row[:id]}")
        OnbaseDocument[row[:id]].delete
      end
    end
  end


  def unlink
    self.class.delete_existing_relationships(self, bump_lock_version = true, force = true)
    self.class.update_mtime_for_ids([self.id])
  end


  def linked_record_uri
    linked_record && linked_record.uri
  end


  private


  def linked_record
    @linked_record ||= related_records(:onbase_document)[0]
  end


  def linked_record_display
    if linked_record
      if linked_record.respond_to?(:display_string)
        linked_record.display_string
      else
        "#{linked_record.class} #{linked_record.id}"
      end
    else
      "unlinked"
    end
  end


end
