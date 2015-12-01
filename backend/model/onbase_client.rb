require 'net/http'
require 'net/http/post/multipart'


class OnbaseClient

  def initialize(opts = {})
    @base_url = AppConfig[:onbase_robi_url]
    @username = AppConfig[:onbase_robi_username]
    @password = AppConfig[:onbase_robi_password]

    @user = opts.fetch(:user)
  end


  def maybe_parse_json(response)
    begin
      ASUtils.json_parse(response.body)
    rescue JSON::ParserError
      Log.error("Couldn't parse response as JSON: #{response.inspect} -- #{response.body}")
      raise ReferenceError.new("Unrecognized response from Onbase web service")
    end
  end


  def upload(file_stream, file_name, content_type, doc_type, keywords = {})

    # add the filename to the keyword list
    keywords[:file_name_keyword] = file_name

    upload_url = url('', {"documentTypeName" => doc_type})
    req = Net::HTTP::Post::Multipart.new(upload_url.request_uri,
                                         "file" => UploadIO.new(file_stream, content_type, file_name),
                                         "keywordData" => {"keywords" => format_keywords(keywords)}.to_json)

    req.basic_auth @username, @password

    res = http_request(upload_url) do |http|
      http.request(req)
    end

    if res.code =~ /^2/
      ASUtils.json_parse(res.body)
    else
      error = maybe_parse_json(res)
      Log.error(error)
      raise ReferenceError.new(error["message"])
    end
  end


  def get(suffix, headers = {})
    get_url = url(suffix)

    http_request(get_url) do |http|
      req = Net::HTTP::Get.new(get_url.request_uri)

      headers.each {|k,v| req[k] = v }

      req.basic_auth @username, @password
      response = http.request(req)

      if response.code != "200"
        raise ConflictException.new("Failure in GET request from onbase: #{response.body}")
      end

      response
    end
  end


  def get_json(suffix)
    res = get(suffix, {"Accept" => "text/json"})
    maybe_parse_json(res)
  end


  def put_json(suffix, json)
    put_url = url(suffix)

    http_request(put_url) do |http|
      req = Net::HTTP::Put.new(put_url.request_uri)
      req['Content-type'] = 'text/json'
      req.body = json
      req.basic_auth @username, @password
      response = http.request(req)

      if response.code !~ /^2/
        raise ConflictException.new("Failure in PUT request to onbase: #{response.body}")
      end
      response
    end
  end


  RecordStream = Struct.new(:content_type, :content_length, :body)

  def stream_record(onbase_id)
    get_url = url(onbase_id)

    http_request(get_url) do |http|
      req = Net::HTTP::Get.new(get_url.request_uri)

      req.basic_auth @username, @password

      http.request(req) do |resp|
        buffer = FileBuffer.new

        resp.read_body do |chunk|
          buffer << chunk
        end

        return RecordStream.new(resp['Content-Type'], resp['Content-Length'], buffer)
      end
    end

    # If all else fails...
    nil
  end


  def add_to_keywords(onbase_id, keywords)
    onbase_keywords = get_keywords(onbase_id)
    
    # save the file name
    onbase_filename = parse_onbase_filename(onbase_keywords)
    
    # find any potential user input keywords
    keywords, onbase_only_keywords = user_input_keywords(keywords, onbase_keywords)
  
    # find any dates that may have already been set
    keywords, onbase_date_keywords = onbase_dates(keywords, onbase_keywords)

    # the AS generated data minus the user input keywords
    formatted_keywords = filter_onbase_dates(format_keywords(keywords), onbase_date_keywords)

    # we now preference the ArchivesSpace keywords on the merge since we've already extracted the pieces we want to keep
    merged = onbase_keywords.merge('keywords' => formatted_keywords.concat(onbase_only_keywords).concat(onbase_date_keywords).concat(onbase_filename))
    
    put_keywords(onbase_id, merged)
    
  end

  def get_keywords(onbase_id)
    get_json("#{onbase_id}/keywords")
  end

  def put_keywords(onbase_id, keywords)
    put_json("#{onbase_id}/keywords", keywords.to_json)
  end

  def record_exists?(onbase_id)
    get_url = url(onbase_id)

    http_request(get_url) do |http|
      req = Net::HTTP::Get.new(get_url.request_uri)

      req.basic_auth @username, @password
      http.request(req) do |response|
        if response.code == "200"
          return true
        elsif response.code == "404"
          return false
        else
          raise ConflictException.new("Unknown record status for #{onbase_id}")
        end
      end
    end

  end

  def http_delete(suffix)
    delete_url = url(suffix)

    http_request(delete_url) do |http|
      req = Net::HTTP::Delete.new(delete_url.request_uri)
      req.basic_auth @username, @password

      response = http.request(req)

      if response.code !~ /^2/
        raise ConflictException.new("Failure in DELETE request to onbase: #{response.body}")
      end

      response
    end
  end

  def delete(onbase_id)
    if record_exists?(onbase_id)
      begin
        http_delete(onbase_id) && true
      rescue
        Log.error("Delete failed for record: #{onbase_id}")
        Log.exception($!)

        false
      end
    else
      # Nothing to do, so pretend it all worked.
      true
    end
  end


  private
  
  def parse_onbase_filename(onbase_keywords)
    onbase_filename = onbase_keywords['keywords'].select { |k| [KeywordNameMapper.translate(:file_name_keyword)].include?(k['keywordTypeName'])}
    
    return onbase_filename
  end
  
  def user_input_keywords(keywords, onbase_keywords)
    # find the not_generated, ie user input keywords, keys and move them to a new array to compare to the fetched keywords from onbase
    keys_to_keep = []
    keywords.delete_if do |keyword|
      if keyword[0] == KeywordNameMapper.translate(:not_generated)
        keys_to_keep.push(keyword[1])
        true
      end
    end
    
    # the onBase only data that has the keywords that we know are not generated by the system
    onbase_only_keywords = onbase_keywords['keywords'].select { |k| keys_to_keep.include?(k['keywordTypeName'])}
    
    return keywords, onbase_only_keywords
  end
  
  
  def onbase_dates(keywords, onbase_keywords)
    # find potential date keys to compare to dates that may have been set already
    date_keys_to_watch = []
    keywords.delete_if do |keyword|
      if keyword[0] == KeywordNameMapper.translate(:potential_date_keys)
        date_keys_to_watch.push(keyword[1])
        true
      end
    end

    # date keywords already set in onBase
    onbase_date_keywords = onbase_keywords['keywords'].select { |k| date_keys_to_watch.include?(k['keywordTypeName'])}
    
    return keywords, onbase_date_keywords
  end
  
  
  def filter_onbase_dates(formatted_keywords, onbase_date_keywords)
    #for later comparison with the AS generated keywords
    onbase_dateKeywordTypeName = []
    onbase_date_keywords.each do |onbaseKey|
      onbase_dateKeywordTypeName.push(onbaseKey['keywordTypeName'])
    end
    
    # remove the keywords for already set dates
    formatted_keywords.reject! { |h| onbase_dateKeywordTypeName.include? h['keywordTypeName']}
    
    return formatted_keywords
    
  end


  def url(suffix, params = {})
    s = "#{@base_url}/#{suffix}".gsub(/\/+$/, '')
    uri = URI(s)
    uri.query = URI.encode_www_form(params.merge('logUser' => @user))

    uri
  end


  def merge_keywords(*keywords)
    # 2015-11-13 - Joshua Shaw - I believe this is now uneccessary.
    # Previously we had a .reverse before the uniq to favor keeping the more
    # recent keywords, but this messes up the "current_date" keyword, so we took
    # it out.  Now when a keyword is set it stays set and can't be overridden.    
    
    keywords.reduce {|k1, k2| k1 + k2}.uniq {|k| k['keywordTypeName']}

  end


  def format_keywords(keywords)
    keywords.map do |name, value|
      {
        "keywordTypeName" => KeywordNameMapper.translate(name),
        "keywordValue" => value
      }
    end
  end


  def http_request(url)
    Net::HTTP.start(url.host, url.port,
                    :use_ssl => url.scheme == 'https',
                    :read_timeout => 60,
                    :open_timeout => 60,
                    :ssl_timeout => 60) do |http|
      yield(http)
    end
  end

end
