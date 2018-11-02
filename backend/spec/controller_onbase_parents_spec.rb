require 'spec_helper'
require_relative 'factories'

describe 'Onbase Document parents controller' do

  it "lets you create an archival object with an onbase document" do
    onbase_document = create(:json_onbase_document)
    archival_object = create(:json_archival_object, :onbase_documents => [{:ref => onbase_document.uri}])
    JSONModel(:archival_object).find(archival_object.id).onbase_documents[0]['ref'].should eq(onbase_document.uri)
  end

end
