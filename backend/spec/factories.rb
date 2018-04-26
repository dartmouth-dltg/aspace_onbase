require 'factory_girl'

FactoryGirl.define do

  factory :json_onbase_document, class: JSONModel(:onbase_document) do
      onbase_id { generate(:alphanumstr) }
      document_type { generate(:alphanumstr) }
      keywords { generate(:alphanumstr) }
  end

end
