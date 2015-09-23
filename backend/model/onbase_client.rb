require 'net/http'
require 'net/http/post/multipart'

class OnbaseClient

  def initialize(opts = {})
    @base_url = 'https://onbase-dev.dartmouth.edu/api/asrobiservice/api/documents'
    @username = ENV.fetch("ONBASE_USERNAME")
    @password = ENV.fetch("ONBASE_PASSWORD")

    @user = opts.fetch(:user)
  end


  def upload(file_stream, file_name, content_type, doc_type, keywords = {})
    upload_url = url('', {"documentTypeName" => doc_type})
    req = Net::HTTP::Post::Multipart.new(upload_url.request_uri,
                                         "file" => UploadIO.new(file_stream, content_type, file_name),
                                         "keywordData" => {"keywords" => format_keywords(keywords)}.to_json)

    req.basic_auth @username, @password

    res = Net::HTTP.start(upload_url.host, upload_url.port, :use_ssl => upload_url.scheme == 'https') do |http|
      http.request(req)
    end

    if res.code =~ /^2/
      ASUtils.json_parse(res.body)
    else
      error = ASUtils.json_parse(res.body)
      Log.error(error)
      raise ReferenceError.new(error["message"])
    end
  end


  def get(suffix, headers = {})
    get_url = url(suffix)

    Net::HTTP.start(get_url.host, get_url.port, :use_ssl => get_url.scheme == 'https') do |http|
      req = Net::HTTP::Get.new(get_url.request_uri)

      headers.each {|k,v| req[k] = v }

      req.basic_auth @username, @password
      response = http.request(req)

      if response.code != "200"
        raise "Failure in GET request from onbase: #{response.body}"
      end

      response
    end
  end


  def get_json(suffix)
    res = get(suffix, {"Accept" => "text/json"})
    p res
    p res.body
    ASUtils.json_parse(res.body)
  end


  def put_json(suffix, json)
    put_url = url(suffix)

    p put_url
    p json

    Net::HTTP.start(put_url.host, put_url.port, :use_ssl => put_url.scheme == 'https') do |http|
      req = Net::HTTP::Put.new(put_url.request_uri)
      req['Content-type'] = 'text/json'
      req.body = json
      req.basic_auth @username, @password

      response = http.request(req)

      if response.code !~ /^2/
        raise "Failure in PUT request to onbase: #{response.body}"
      end

      p response.body

      response
    end
  end


  def add_to_keywords(onbase_id, keywords)
    onbase_keywords = get_keywords(onbase_id)

    merged = onbase_keywords.merge('keywords' => merge_keywords(onbase_keywords['keywords'], format_keywords(keywords)))
    p put_keywords(onbase_id, merged)
  end


  def get_keywords(onbase_id)
    get_json("#{onbase_id}/keywords")
  end

  def put_keywords(onbase_id, keywords)
    put_json("#{onbase_id}/keywords", keywords.to_json)
  end


  private


  def url(suffix, params = {})
    s = "#{@base_url}/#{suffix}".gsub(/\/+$/, '')
    uri = URI(s)
    uri.query = URI.encode_www_form(params.merge('logUser' => @user))

    uri
  end


  def merge_keywords(*keywords)
    keywords.reduce {|k1, k2| k1 + k2}.reverse.uniq {|k| k['keywordTypeName']}
  end


  def format_keywords(keywords)
    keywords.map do |name, value|
      {
        "keywordTypeName" => name,
        "keywordValue" => value
      }
    end
  end

end