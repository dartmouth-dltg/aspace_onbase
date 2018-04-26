require 'spec_helper'
require 'webmock/rspec'

describe 'Onbase Client model' do

  it "can upload a file and get it back" do

    doc_type = "SPCL-Deed"
    log_user = "OWM:F001GQB"
    doc_id = "999"

    stub_request(:post, "https://me:reallyme@onbase-dev.dartmouth.edu/api/OWMROBIInstance/api/documents/")
        .with(:query => {"documentTypeName" => doc_type, "logUser" => log_user})
        .to_return(:body => doc_id, :status => 200,
                  :headers => { 'Content-Length' => 3 })

    stub_request(:get, "me:reallyme@onbase-dev.dartmouth.edu:443/api/OWMROBIInstance/api/documents/999")

    opts = {:user => "testuser"}
    client = OnbaseClient.new(opts)

    up_file = File.new(__FILE__, 'r')
    docId = client.upload(up_file, "test.txt", "text/plain", doc_type, log_user, '{"moo": "moo"}')
    docId.should eq(doc_id)
    down_file = client.get(docId)
  end

end
