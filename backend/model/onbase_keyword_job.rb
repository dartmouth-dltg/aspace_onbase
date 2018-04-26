class OnbaseKeywordJob < Sequel::Model(:onbase_keyword_job)

  JOB_RETRY_TIME = 120

  def self.create(onbase_document, keywords, user)
    super(:onbase_id => onbase_document.onbase_id,
          :keywords => keywords.to_a.to_json, #convert hash to array first to preserve the duplicate keys that may be found in the hash
          :status => "new",
          :user => user,
          :system_mtime => Time.now)
  end

  def self.process_jobs
    Log.debug("AspaceOnbase Job: Upload Document Keywords")
    work_list = OnbaseKeywordJob.filter(:status => "new")

    work_list.each do |job|
      update_count = DB.open do
        OnbaseKeywordJob.filter(:status => "new", :id => job.id).update(:status => "running",
                                                                        :system_mtime => Time.now)
      end

      if update_count == 0
        # Someone else got in before we did
        next
      end

      job.upload_keywords
    end

    find_unfinished_jobs
  end


  def upload_keywords
    # HTTP
    client = OnbaseClient.new(:user => user)

    client.add_to_keywords(onbase_id, ASUtils.json_parse(keywords))

    self.update(:status => "done", :system_mtime => Time.now)
  end


  private

  def self.find_unfinished_jobs
    # mark any job older than N minutes as new so it gets retried
    DB.open do
      OnbaseKeywordJob.filter(:status => "pending").
        where { system_mtime < (Time.now - JOB_RETRY_TIME) }.
        update(:status => "new")
    end
  end

end
