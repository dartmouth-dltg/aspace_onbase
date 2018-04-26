require 'spec_helper'
require_relative 'factories'

describe 'Onbase Document controller' do

  it "can create an onbase document" do
    opts = {:document_type => 'Serious stuff'}

    id = create(:json_onbase_document, opts).id
    JSONModel(:onbase_document).find(id).document_type.should eq(opts[:name])
   end

end
