# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# test whether a Sunspot server is running
if(!Sunspot.solr_running?)
  puts "ERROR! Unable to seed the database!"
  puts "Solr must be running in order to create and index AaE objects"
  puts "Please run solr before continuing - in development this can be done by typing rake sunspot:solr:start.  See rake --tasks for other tasks"
  exit(1)
end

@aae_database = ActiveRecord::Base.connection.instance_variable_get("@config")[:database]
@darmokdatabase = Settings.darmokdatabase

def transfer_accounts
  # import all non-retired/"valid" accounts
  puts 'Transferring users...'
  # preserve id's here
  account_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
    INSERT INTO #{@aae_database}.users (id, darmok_id, type, login, name, email, title, position_id, location_id, county_id, retired, is_admin, phone_number, aae_responder, time_zone, is_question_wrangler, vacated_aae_at, first_aae_away_reminder, second_aae_away_reminder, created_at, updated_at)
    SELECT #{@darmokdatabase}.accounts.id, #{@darmokdatabase}.accounts.id, #{@darmokdatabase}.accounts.type, #{@darmokdatabase}.accounts.login, CONCAT(#{@darmokdatabase}.accounts.first_name,' ', #{@darmokdatabase}.accounts.last_name), 
           #{@darmokdatabase}.accounts.email, #{@darmokdatabase}.accounts.title, #{@darmokdatabase}.accounts.position_id, #{@darmokdatabase}.accounts.location_id, #{@darmokdatabase}.accounts.county_id, #{@darmokdatabase}.accounts.retired,
           #{@darmokdatabase}.accounts.is_admin, #{@darmokdatabase}.accounts.phonenumber, #{@darmokdatabase}.accounts.aae_responder, #{@darmokdatabase}.accounts.time_zone, #{@darmokdatabase}.accounts.is_question_wrangler, #{@darmokdatabase}.accounts.vacated_aae_at,
           #{@darmokdatabase}.accounts.first_aae_away_reminder, #{@darmokdatabase}.accounts.second_aae_away_reminder, #{@darmokdatabase}.accounts.created_at, NOW() 
    FROM   #{@darmokdatabase}.accounts
    WHERE  #{@darmokdatabase}.accounts.retired = 0 and #{@darmokdatabase}.accounts.vouched = 1
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(account_insert_query)
  end
  puts " Accounts transferred : #{benchmark.real.round(2)}s"
  
  authmap_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.authmaps (user_id, authname, source, created_at, updated_at) 
    SELECT #{@aae_database}.users.id, CONCAT('https://people.extension.org/',#{@darmokdatabase}.accounts.login), 'people', #{@darmokdatabase}.accounts.created_at, NOW()
    FROM #{@aae_database}.users,#{@darmokdatabase}.accounts
    WHERE #{@aae_database}.users.id = #{@darmokdatabase}.accounts.id
  END_SQL
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(authmap_insert_query)
  end
  
  puts " Authmaps transferred: #{benchmark.real.round(2)}s"
end

def transfer_locations
  puts 'Transferring locations...'
  location_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.locations (id, fipsid, entrytype, name, abbreviation, office_link, created_at, updated_at)
    SELECT #{@darmokdatabase}.locations.id, #{@darmokdatabase}.locations.fipsid, #{@darmokdatabase}.locations.entrytype, #{@darmokdatabase}.locations.name, #{@darmokdatabase}.locations.abbreviation, #{@darmokdatabase}.locations.office_link, NOW(), NOW()
    FROM #{@darmokdatabase}.locations
  END_SQL
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(location_insert_query)
  end
  
  puts " Locations transferred: #{benchmark.real.round(2)}s"
end

def transfer_expertise_locations
  puts 'Transferring expertise locations ...'
  location_expertise_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.locations_users (location_id, user_id)
    SELECT #{@darmokdatabase}.expertise_locations_users.expertise_location_id, #{@darmokdatabase}.expertise_locations_users.user_id
    FROM #{@darmokdatabase}.expertise_locations_users
  END_SQL
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(location_expertise_insert_query)
  end
  
  puts " Location Expertise transferred: #{benchmark.real.round(2)}s"
end


def transfer_counties
  puts 'Transferring counties...'
  county_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.counties (id, fipsid, location_id, state_fipsid, countycode, name, censusclass, created_at, updated_at)
    SELECT #{@darmokdatabase}.counties.id, #{@darmokdatabase}.counties.fipsid, #{@darmokdatabase}.counties.location_id, #{@darmokdatabase}.counties.state_fipsid, #{@darmokdatabase}.counties.countycode, #{@darmokdatabase}.counties.name, #{@darmokdatabase}.counties.censusclass, NOW(), NOW()
    FROM #{@darmokdatabase}.counties
  END_SQL
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(county_insert_query)
  end
  
  puts " Counties transferred: #{benchmark.real.round(2)}s"
end

def transfer_expertise_counties
  puts 'Transferring expertise counties...'
  county_expertise_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.counties_users (county_id, user_id)
    SELECT #{@darmokdatabase}.expertise_counties_users.expertise_county_id, #{@darmokdatabase}.expertise_counties_users.user_id
    FROM #{@darmokdatabase}.expertise_counties_users
  END_SQL
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(county_expertise_insert_query)
  end
  
  puts " County Expertise transferred: #{benchmark.real.round(2)}s"
end


def transfer_communities_to_groups
  puts 'Transferring communities to groups...'
  # preserve id's
  group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (id, name, description, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_url, group_notify, creator_id, created_at, updated_at)
    SELECT #{@darmokdatabase}.communities.id, #{@darmokdatabase}.communities.name, #{@darmokdatabase}.communities.description, #{@darmokdatabase}.communities.active, #{@darmokdatabase}.communities.created_by,
           #{@darmokdatabase}.widgets.fingerprint, #{@darmokdatabase}.widgets.upload_capable, #{@darmokdatabase}.widgets.show_location, #{@darmokdatabase}.widgets.enable_tags, #{@darmokdatabase}.widgets.location_id,
           #{@darmokdatabase}.widgets.county_id, #{@darmokdatabase}.widgets.old_widget_url, #{@darmokdatabase}.widgets.group_notify, #{@darmokdatabase}.widgets.user_id, #{@darmokdatabase}.widgets.created_at, NOW()
    FROM #{@darmokdatabase}.communities
    JOIN #{@darmokdatabase}.widgets ON #{@darmokdatabase}.widgets.id = #{@darmokdatabase}.communities.widget_id
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(group_insert_query)
  end
  
  puts " Groups transferred: #{benchmark.real.round(2)}s"
end

def transfer_widget_community_connections_to_group_connections
  puts 'Transferring group connections ...'
  group_connection_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.group_connections(user_id, group_id, connection_type, connection_code, send_notifications, connected_by, created_at, updated_at)
  SELECT #{@darmokdatabase}.communityconnections.user_id, #{@darmokdatabase}.communityconnections.community_id, #{@darmokdatabase}.communityconnections.connectiontype, #{@darmokdatabase}.communityconnections.connectioncode, #{@darmokdatabase}.communityconnections.sendnotifications,
         #{@darmokdatabase}.communityconnections.connected_by, #{@darmokdatabase}.communityconnections.created_at, NOW()  
  FROM  #{@darmokdatabase}.communityconnections
  JOIN  #{@aae_database}.groups ON #{@aae_database}.groups.id = #{@darmokdatabase}.communityconnections.community_id
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(group_connection_insert_query)
  end
  
  puts " Group Connections transferred: #{benchmark.real.round(2)}s"
end

def transfer_group_events
  puts 'Transferring group events...'
  group_connection_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.group_events(created_by, recipient_id, description, event_code, group_id, created_at, updated_at)
  SELECT #{@darmokdatabase}.activities.created_by, #{@darmokdatabase}.activities.user_id, '', #{@darmokdatabase}.activities.activitycode, 
         #{@darmokdatabase}.activities.community_id, #{@darmokdatabase}.activities.created_at, NOW()
  FROM  #{@darmokdatabase}.activities
  JOIN   #{@aae_database}.groups ON #{@aae_database}.groups.id = #{@darmokdatabase}.activities.community_id
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(group_connection_insert_query)
    # fill in the description based on established constants in GroupEvent
    group_event_list = GroupEvent.all
    group_event_list.each do |ge|
      ge.update_attribute(:description, GroupEvent::GROUP_EVENT_STRINGS[ge.event_code])
    end
  end
      
  puts " Group Events transferred: #{benchmark.real.round(2)}s"
end

def transfer_questions
  puts 'Transferring questions...'
  question_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.questions(id, current_resolver, contributing_content_id, status, body, title, private, assignee_id, duplicate, external_app_id, submitter_email, resolved_at, external_id, question_updated_at, current_response, current_resolver_email, question_fingerprint, submitter_firstname, submitter_lastname, county_id, location_id, spam, user_ip, user_agent, referrer, widget_name, status_state, zip_code, widget_id, submitter_id, show_publicly, last_assigned_at, last_opened_at, is_api, contributing_content_type, created_at, updated_at)
  SELECT #{@darmokdatabase}.submitted_questions.id, #{@darmokdatabase}.submitted_questions.resolved_by, #{@darmokdatabase}.submitted_questions.contributing_content_id, #{@darmokdatabase}.submitted_questions.status, #{@darmokdatabase}.submitted_questions.asked_question,
         null, true, #{@darmokdatabase}.submitted_questions.user_id, #{@darmokdatabase}.submitted_questions.duplicate, #{@darmokdatabase}.submitted_questions.external_app_id, #{@darmokdatabase}.submitted_questions.submitter_email,
         #{@darmokdatabase}.submitted_questions.resolved_at, #{@darmokdatabase}.submitted_questions.external_id, #{@darmokdatabase}.submitted_questions.question_updated_at, #{@darmokdatabase}.submitted_questions.current_response,
         #{@darmokdatabase}.submitted_questions.resolver_email, #{@darmokdatabase}.submitted_questions.question_fingerprint, #{@darmokdatabase}.submitted_questions.submitter_firstname, #{@darmokdatabase}.submitted_questions.submitter_lastname,
         #{@darmokdatabase}.submitted_questions.county_id, #{@darmokdatabase}.submitted_questions.location_id, #{@darmokdatabase}.submitted_questions.spam, #{@darmokdatabase}.submitted_questions.user_ip, #{@darmokdatabase}.submitted_questions.user_agent, 
         #{@darmokdatabase}.submitted_questions.referrer, #{@darmokdatabase}.submitted_questions.widget_name, #{@darmokdatabase}.submitted_questions.status_state, #{@darmokdatabase}.submitted_questions.zip_code,
         #{@darmokdatabase}.communities.id, #{@darmokdatabase}.submitted_questions.submitter_id, #{@darmokdatabase}.submitted_questions.show_publicly, #{@darmokdatabase}.submitted_questions.last_assigned_at,
         #{@darmokdatabase}.submitted_questions.last_opened_at, #{@darmokdatabase}.submitted_questions.is_api, #{@darmokdatabase}.submitted_questions.contributing_content_type, #{@darmokdatabase}.submitted_questions.created_at, NOW()       
  FROM  #{@darmokdatabase}.submitted_questions
  LEFT JOIN #{@darmokdatabase}.communities ON #{@darmokdatabase}.communities.widget_id = #{@darmokdatabase}.submitted_questions.widget_id
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_transfer_query)
  end
  
  puts " Questions transferred: #{benchmark.real.round(2)}s"
end

def transfer_assets
  puts 'Transferring assets...'
  question_asset_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.assets(type, assetable_id, assetable_type, attachment_file_name, attachment_content_type, attachment_file_size, attachment_updated_at, created_at, updated_at)
  SELECT 'Question::Image', #{@darmokdatabase}.file_attachments.submitted_question_id, 'Question', #{@darmokdatabase}.file_attachments.attachment_file_name, #{@darmokdatabase}.file_attachments.attachment_content_type,
         #{@darmokdatabase}.file_attachments.attachment_file_size, #{@darmokdatabase}.file_attachments.attachment_updated_at, #{@darmokdatabase}.file_attachments.created_at, NOW()
  FROM   #{@darmokdatabase}.file_attachments
  WHERE  #{@darmokdatabase}.file_attachments.submitted_question_id IS NOT NULL AND #{@darmokdatabase}.file_attachments.response_id IS NULL
  END_SQL
  
  response_asset_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.assets(type, assetable_id, assetable_type, attachment_file_name, attachment_content_type, attachment_file_size, attachment_updated_at, created_at, updated_at)
  SELECT 'Response::Image', #{@darmokdatabase}.file_attachments.response_id, 'Response', #{@darmokdatabase}.file_attachments.attachment_file_name, #{@darmokdatabase}.file_attachments.attachment_content_type,
         #{@darmokdatabase}.file_attachments.attachment_file_size, #{@darmokdatabase}.file_attachments.attachment_updated_at, #{@darmokdatabase}.file_attachments.created_at, NOW()
  FROM   #{@darmokdatabase}.file_attachments
  WHERE  #{@darmokdatabase}.file_attachments.submitted_question_id IS NULL AND #{@darmokdatabase}.file_attachments.response_id IS NOT NULL
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_asset_transfer_query)
    ActiveRecord::Base.connection.execute(response_asset_transfer_query)
  end
  
  puts " Assets transferred: #{benchmark.real.round(2)}s"
end

def transfer_question_events
  puts 'Transferring question events...'
  question_events_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.question_events(question_id, submitter_id, initiated_by_id, recipient_id, response_id, response, event_state, contributing_content_id, tags, additional_data, previous_event_id, duration_since_last, previous_recipient_id, previous_initiator_id, previous_handling_event_id, duration_since_last_handling_event, previous_handling_event_state, previous_handling_recipient_id, previous_handling_initiator_id, previous_tags, contributing_content_type, created_at, updated_at)
  SELECT #{@darmokdatabase}.submitted_question_events.submitted_question_id, #{@darmokdatabase}.submitted_question_events.submitter_id, #{@darmokdatabase}.submitted_question_events.initiated_by_id, #{@darmokdatabase}.submitted_question_events.recipient_id,
         #{@darmokdatabase}.submitted_question_events.response_id, #{@darmokdatabase}.submitted_question_events.response, #{@darmokdatabase}.submitted_question_events.event_state, 
         #{@darmokdatabase}.submitted_question_events.contributing_content_id, #{@darmokdatabase}.submitted_question_events.category, #{@darmokdatabase}.submitted_question_events.additionaldata, 
         #{@darmokdatabase}.submitted_question_events.previous_event_id, #{@darmokdatabase}.submitted_question_events.duration_since_last, #{@darmokdatabase}.submitted_question_events.previous_recipient_id,
         #{@darmokdatabase}.submitted_question_events.previous_initiator_id, #{@darmokdatabase}.submitted_question_events.previous_handling_event_id, #{@darmokdatabase}.submitted_question_events.duration_since_last_handling_event,
         #{@darmokdatabase}.submitted_question_events.previous_handling_event_state, #{@darmokdatabase}.submitted_question_events.previous_handling_recipient_id, #{@darmokdatabase}.submitted_question_events.previous_handling_initiator_id,
         #{@darmokdatabase}.submitted_question_events.previous_category, #{@darmokdatabase}.submitted_question_events.contributing_content_type, #{@darmokdatabase}.submitted_question_events.created_at, NOW()       
  FROM  #{@darmokdatabase}.submitted_question_events
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_events_transfer_query)
  end
  
  puts " Question Events transferred: #{benchmark.real.round(2)}s"
end

def transfer_responses
  puts 'Transferring responses...'
  responses_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.responses(resolver_id, submitter_id, question_id, body, duration_since_last, sent, contributing_content_id, signature, user_ip, user_agent, referrer, contributing_content_type, created_at, updated_at)
  SELECT #{@darmokdatabase}.responses.resolver_id, #{@darmokdatabase}.responses.submitter_id, #{@darmokdatabase}.responses.submitted_question_id, #{@darmokdatabase}.responses.response, #{@darmokdatabase}.responses.duration_since_last,
         #{@darmokdatabase}.responses.sent, #{@darmokdatabase}.responses.contributing_content_id, #{@darmokdatabase}.responses.signature, #{@darmokdatabase}.responses.user_ip, #{@darmokdatabase}.responses.user_agent, 
         #{@darmokdatabase}.responses.referrer, #{@darmokdatabase}.responses.contributing_content_type, #{@darmokdatabase}.responses.created_at, NOW()
  FROM   #{@darmokdatabase}.responses
  END_SQL

  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(responses_transfer_query)
  end
  
  puts " Responses transferred: #{benchmark.real.round(2)}s"
end


transfer_accounts
transfer_locations
transfer_counties
transfer_communities_to_groups
transfer_widget_community_connections_to_group_connections
transfer_group_events
transfer_questions
transfer_assets
transfer_expertise_locations
transfer_expertise_counties
transfer_question_events
transfer_responses

