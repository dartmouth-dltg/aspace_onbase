require 'db/migrations/utils'

Sequel.migration do
  
  ONBASE_ID_MAP = {
    2260131 => 2284804,
    2260122 => 2284805,
    2255923 => 2284806,
    2114377 => 2284807,
    2070991 => 2284808,
    2069410 => 2284809,
    1982453 => 2284810,
    1982451 => 2284811,
    1982447 => 2284812,
    1982442 => 2284814,
    1963987 => 2284815,
    1916513 => 2284816,
    1680652 => 2284818,
    1659563 => 2284819,
    1652239 => 2284821,
    1650071 => 2284822,
    1649837 => 2284823,
    1649827 => 2284824,
    1649820 => 2284825,
    1649813 => 2284826,
    1648144 => 2284827,
    1647250 => 2284828,
    1646891 => 2284829,
    1642230 => 2284830,
    1642226 => 2284831,
    1635834 => 2284832,
    1635832 => 2284833,
    1620639 => 2284834,
    1620461 => 2284835,
    1593141 => 2284836,
    1578116 => 2284837,
    1534256 => 2284838,
    1533551 => 2284839,
    1529264 => 2284840,
    1527139 => 2284841,
    1515003 => 2284842,
    1475099 => 2284843,
    1475090 => 2284844,
    1475058 => 2284845,
    1474525 => 2284846,
    1331589 => 2284850,
    976251 => 2284853,
    976243 => 2284855,
    976241 => 2284856,
    976229 => 2284857,
    976204 => 2284858,
    976130 => 2284859,
    976075 => 2284861,
    559067 => 2284862,
    556400 => 2284863,
    556371 => 2284864,
    551562 => 2284865,
    551560 => 2284866,
    551559 => 2284867,
    551558 => 2284868,
    551557 => 2284869,
    551556 => 2284870,
    551555 => 2284871,
    551554 => 2284872,
    551553 => 2284873,
    551552 => 2284874,
    551551 => 2284875,
    551550 => 2284876,
    551549 => 2284877,
    551548 => 2284878,
    551547 => 2284879,
    551546 => 2284880,
    551542 => 2284881,
    551541 => 2284882,
    551539 => 2284883,
    534359 => 2284884,
    534219 => 2284885,
    534218 => 2284886
  }
  
  ONBASE_TABLES = [:onbase_document, :onbase_keyword_job]

  up do
    
    puts ""
    puts "*" * 72
    puts "Migrating OnBase IDs to new IDs"
    puts "*" * 72
    
    ONBASE_TABLES.each do |table|
      
      puts ""
      puts "Updating OnBase table: #{table}"
      puts ""
      
      self[table].each do |row|
        current_onbase_id = row[:onbase_id].to_i
        current_id = row[:id]
        if ONBASE_ID_MAP[current_onbase_id].nil?
          puts "OnBase ID #{current_onbase_id} was not found in the OnBase old->new id mapping."
          if table == :onbase_keyword_job
            puts "Setting Keyword Job status to 'done.'"
            self[table].filter(:id => current_id).update(:status => "done")
          end
        else
          puts "Updating OnBase ID #{current_onbase_id} to new ID #{ONBASE_ID_MAP[current_onbase_id]}"
          self[table].filter(:id => current_id).update(:onbase_id => ONBASE_ID_MAP[current_onbase_id],
                                                       :system_mtime => Time.now)
        end
        
      end      
    end
    
  end
  
  down do
  end

end