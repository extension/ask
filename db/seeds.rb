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
    INSERT INTO #{@aae_database}.users (id, darmok_id, kind, login, first_name, last_name, public_name, email, title, position_id, location_id, county_id, retired, is_admin, phone_number, aae_responder, time_zone, is_question_wrangler, vacated_aae_at, first_aae_away_reminder, second_aae_away_reminder, current_sign_in_at, last_sign_in_at, created_at, updated_at)
    SELECT #{@darmokdatabase}.accounts.id, #{@darmokdatabase}.accounts.id, #{@darmokdatabase}.accounts.type, #{@darmokdatabase}.accounts.login, #{@darmokdatabase}.accounts.first_name, #{@darmokdatabase}.accounts.last_name, NULL, 
           #{@darmokdatabase}.accounts.email, #{@darmokdatabase}.accounts.title, #{@darmokdatabase}.accounts.position_id, #{@darmokdatabase}.accounts.location_id, #{@darmokdatabase}.accounts.county_id, #{@darmokdatabase}.accounts.retired,
           #{@darmokdatabase}.accounts.is_admin, #{@darmokdatabase}.accounts.phonenumber, #{@darmokdatabase}.accounts.aae_responder, #{@darmokdatabase}.accounts.time_zone, #{@darmokdatabase}.accounts.is_question_wrangler, #{@darmokdatabase}.accounts.vacated_aae_at,
           #{@darmokdatabase}.accounts.first_aae_away_reminder, #{@darmokdatabase}.accounts.second_aae_away_reminder, #{@darmokdatabase}.accounts.last_login_at, #{@darmokdatabase}.accounts.last_login_at, #{@darmokdatabase}.accounts.created_at, NOW() 
    FROM   #{@darmokdatabase}.accounts
  END_SQL
  
  # all public accounts should have the aae_responder field set to false, they were set to true in darmok
  account_aae_responder_update_query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{@aae_database}.users
    SET    #{@aae_database}.users.aae_responder = 0 
    WHERE  #{@aae_database}.users.kind = 'PublicUser'
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(account_insert_query)
    ActiveRecord::Base.connection.execute(account_aae_responder_update_query)
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
  INSERT INTO #{@aae_database}.user_locations (location_id, user_id)
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
  INSERT INTO #{@aae_database}.user_counties (county_id, user_id)
    SELECT #{@darmokdatabase}.expertise_counties_users.expertise_county_id, #{@darmokdatabase}.expertise_counties_users.user_id
    FROM #{@darmokdatabase}.expertise_counties_users
  END_SQL
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(county_expertise_insert_query)
  end
  
  puts " County Expertise transferred: #{benchmark.real.round(2)}s"
end


def transfer_widget_communities_to_groups
  puts 'Transferring widget communities to groups...'
  # preserve id's
  group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (id, name, description, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_url, group_notify, created_at, updated_at)
    SELECT #{@darmokdatabase}.communities.id, #{@darmokdatabase}.widgets.name, #{@darmokdatabase}.communities.description, #{@darmokdatabase}.communities.active, #{@darmokdatabase}.communities.created_by,
           #{@darmokdatabase}.widgets.fingerprint, #{@darmokdatabase}.widgets.upload_capable, #{@darmokdatabase}.widgets.show_location, #{@darmokdatabase}.widgets.enable_tags, #{@darmokdatabase}.widgets.location_id,
           #{@darmokdatabase}.widgets.county_id, #{@darmokdatabase}.widgets.old_widget_url, #{@darmokdatabase}.widgets.group_notify, #{@darmokdatabase}.widgets.created_at, NOW()
    FROM #{@darmokdatabase}.communities
    JOIN #{@darmokdatabase}.widgets ON #{@darmokdatabase}.widgets.id = #{@darmokdatabase}.communities.widget_id
  END_SQL
  
  # we need to add the Question Wrangler community to groups which is a special case. the question wrangler community does not have a widget
  # and they're not a selectable area of expertise, but will be a formal and emphasized group in this AaE application and will have a widget.
  wrangler_group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (id, name, description, widget_public_option, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_url, group_notify, created_at, updated_at)
    SELECT #{@darmokdatabase}.communities.id, #{@darmokdatabase}.communities.name, #{@darmokdatabase}.communities.description, true, #{@darmokdatabase}.communities.active, #{@darmokdatabase}.communities.created_by,
           NULL, true, true, false, NULL, NULL, NULL, true, #{@darmokdatabase}.communities.created_at, NOW()
    FROM #{@darmokdatabase}.communities
    WHERE #{@darmokdatabase}.communities.name = 'eXtension Question Wranglers'
  END_SQL
  
  ## While we're inserting groups here, let's add a generic group that will be assigned questions with unaffiliated groups
  orphan_group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (id, name, description, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_url, group_notify, created_at, updated_at)
    VALUES (99999, 'Orphan Group', 'Group that holds orphaned questions that have no other group assignment.', true, #{User.system_user_id}, NULL, false, false, false, NULL, NULL, NULL, false, NOW(), NOW()) 
  END_SQL

  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(group_insert_query)
    ActiveRecord::Base.connection.execute(wrangler_group_insert_query)
    ActiveRecord::Base.connection.execute(orphan_group_insert_query)
  end
  
  # Need to use a little Ruby/Rails here to create a widget for the Question Wrangler group
  wrangler_group = Group.find(:first, :conditions => "name = 'eXtension Question Wranglers'")
  wrangler_group.update_attribute(:widget_fingerprint, generate_widget_fingerprint(wrangler_group.name, wrangler_group.id))
  
  puts " Groups transferred: #{benchmark.real.round(2)}s"
end

def transfer_widget_group_locations
  puts 'Transferring widget group locations and counties...'
  benchmark = Benchmark.measure do
    # run queries to insert into county and location join tables for groups
    Group.where("widget_county_id IS NOT NULL OR widget_location_id IS NOT NULL").each do |g|
      g.group_locations.create(:location_id => g.widget_location_id) if g.widget_location_id.present?
      g.group_counties.create(:county_id => g.widget_county_id) if g.widget_county_id.present?
    end
  end
  puts " Widget group locations and counties transferred: #{benchmark.real.round(2)}s"
end


def transfer_expertise_areas_to_groups
  puts 'Transferring expertise areas to groups...'
  expertise_to_group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (name, description, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_url, group_notify, darmok_expertise_id, created_at, updated_at)
    SELECT  #{@darmokdatabase}.categories.name, '', true, #{User.system_user_id}, NULL, false, false, false, NULL, NULL, NULL, false, #{@darmokdatabase}.categories.id, NOW(), NOW()
    FROM #{@darmokdatabase}.categories
    WHERE #{@darmokdatabase}.categories.parent_id IS NULL
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(expertise_to_group_insert_query)
    # do some ruby here to generate widget fingerprints for the expertise area groups coming in
    expertise_area_groups = Group.where("darmok_expertise_id IS NOT NULL")
    expertise_area_groups.each do |g|
      g.update_attribute(:widget_fingerprint, generate_widget_fingerprint(g.name, g.id))
    end
  end

  puts " Expertise to groups transferred: #{benchmark.real.round(2)}s"
end


def transfer_widget_community_connections_to_group_connections
  # this also creates the group connections for the newly created Question Wrangler group.
  puts 'Transferring group connections ...'
  group_connection_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.group_connections(user_id, group_id, connection_type, connection_code, send_notifications, connected_by, created_at, updated_at)
  SELECT #{@darmokdatabase}.communityconnections.user_id, #{@darmokdatabase}.communityconnections.community_id, #{@darmokdatabase}.communityconnections.connectiontype, #{@darmokdatabase}.communityconnections.connectioncode, #{@darmokdatabase}.communityconnections.sendnotifications,
         #{@darmokdatabase}.communityconnections.connected_by, #{@darmokdatabase}.communityconnections.created_at, NOW()  
  FROM  #{@darmokdatabase}.communityconnections
  JOIN  #{@aae_database}.groups ON #{@aae_database}.groups.id = #{@darmokdatabase}.communityconnections.community_id
  WHERE #{@aae_database}.groups.darmok_expertise_id IS NULL
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(group_connection_insert_query)
  end
  
  puts " Group Connections transferred: #{benchmark.real.round(2)}s"
end

def fill_in_group_connections_for_areas_of_expertise
  puts 'Filling in group connections for areas of expertise ...'
  expertise_group_connection_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.group_connections(user_id, group_id, connection_type, connection_code, send_notifications, connected_by, created_at, updated_at)
  SELECT #{@darmokdatabase}.expertise_areas.user_id, #{@aae_database}.groups.id, 'member', NULL, false, #{User.system_user_id}, #{@darmokdatabase}.expertise_areas.created_at, NOW()
  FROM   #{@darmokdatabase}.expertise_areas
  JOIN   #{@aae_database}.groups ON #{@darmokdatabase}.expertise_areas.category_id = #{@aae_database}.groups.darmok_expertise_id 
  GROUP BY #{@darmokdatabase}.expertise_areas.user_id, #{@darmokdatabase}.expertise_areas.category_id
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(expertise_group_connection_insert_query)
  end
  
  puts " Expertise Group Connections transferred: #{benchmark.real.round(2)}s"
end

def inactivate_widgets_with_no_active_assignees
  # Need to use a little Ruby/Rails here to inactivate widgets for which there are no active assignees signed up for it 
  # (ie. there are either no assignees or all assignees have their vacation prefs on)
  Group.where("active = ?", true).each do |group|
    group.update_attribute(:active, false) if group.assignees.length == 0
  end
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
  INSERT INTO #{@aae_database}.questions(id, current_resolver_id, status, body, title, is_private, is_private_reason, assignee_id, assigned_group_id, duplicate, external_app_id, submitter_email, resolved_at, question_updated_at, current_response, current_resolver_email, question_fingerprint, submitter_firstname, submitter_lastname, county_id, location_id, spam, user_ip, user_agent, referrer, group_name, status_state, zip_code, original_group_id, submitter_id, last_assigned_at, last_opened_at, is_api, created_at, updated_at)
  SELECT #{@darmokdatabase}.submitted_questions.id, #{@darmokdatabase}.submitted_questions.resolved_by, #{@darmokdatabase}.submitted_questions.status, #{@darmokdatabase}.submitted_questions.asked_question,
         null, true, 2, #{@darmokdatabase}.submitted_questions.user_id, #{@darmokdatabase}.communities.id, #{@darmokdatabase}.submitted_questions.duplicate, #{@darmokdatabase}.submitted_questions.external_app_id, #{@darmokdatabase}.submitted_questions.submitter_email,
         #{@darmokdatabase}.submitted_questions.resolved_at, #{@darmokdatabase}.submitted_questions.question_updated_at, #{@darmokdatabase}.submitted_questions.current_response,
         #{@darmokdatabase}.submitted_questions.resolver_email, #{@darmokdatabase}.submitted_questions.question_fingerprint, #{@darmokdatabase}.submitted_questions.submitter_firstname, #{@darmokdatabase}.submitted_questions.submitter_lastname,
         #{@darmokdatabase}.submitted_questions.county_id, #{@darmokdatabase}.submitted_questions.location_id, #{@darmokdatabase}.submitted_questions.spam, #{@darmokdatabase}.submitted_questions.user_ip, #{@darmokdatabase}.submitted_questions.user_agent, 
         #{@darmokdatabase}.submitted_questions.referrer, #{@darmokdatabase}.submitted_questions.widget_name, #{@darmokdatabase}.submitted_questions.status_state, #{@darmokdatabase}.submitted_questions.zip_code,
         #{@darmokdatabase}.communities.id, #{@darmokdatabase}.submitted_questions.submitter_id, #{@darmokdatabase}.submitted_questions.last_assigned_at,
         #{@darmokdatabase}.submitted_questions.last_opened_at, #{@darmokdatabase}.submitted_questions.is_api, #{@darmokdatabase}.submitted_questions.created_at, NOW()       
  FROM  #{@darmokdatabase}.submitted_questions
  LEFT JOIN #{@darmokdatabase}.communities ON #{@darmokdatabase}.communities.widget_id = #{@darmokdatabase}.submitted_questions.widget_id
  END_SQL
  
  # transferring partially phased out contributing question field, only have question now and getting rid of contributing faqs, pages, etc.
  transfer_contributing_question_id_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.questions 
  JOIN #{@darmokdatabase}.submitted_questions ON #{@aae_database}.questions.id = #{@darmokdatabase}.submitted_questions.id
  SET #{@aae_database}.questions.contributing_question_id = #{@darmokdatabase}.submitted_questions.contributing_content_id
  WHERE #{@darmokdatabase}.submitted_questions.contributing_content_type = 'SubmittedQuestion'
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_transfer_query)
    ActiveRecord::Base.connection.execute(transfer_contributing_question_id_query)
    
    # we need to mark the is_private_reason for spam and rejected questions
    spam_questions = Question.where(:spam => true)
    spam_questions.each do |sq|
      sq.update_attribute(:is_private_reason, 4)
    end
    
    # search for spam = false, b/c spam questions are a subset of rejected questions and they've been handled above
    rejected_questions = Question.where({:status_state => 4, :spam => false})
    rejected_questions.each do |rq|
      rq.update_attribute(:is_private_reason, 5)
    end
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
  INSERT INTO #{@aae_database}.question_events(id, question_id, submitter_id, initiated_by_id, recipient_id, response, event_state, tags, additional_data, previous_event_id, duration_since_last, previous_recipient_id, previous_initiator_id, previous_handling_event_id, duration_since_last_handling_event, previous_handling_event_state, previous_handling_recipient_id, previous_handling_initiator_id, previous_tags, created_at, updated_at)
  SELECT #{@darmokdatabase}.submitted_question_events.id, #{@darmokdatabase}.submitted_question_events.submitted_question_id, #{@darmokdatabase}.submitted_question_events.submitter_id, #{@darmokdatabase}.submitted_question_events.initiated_by_id, #{@darmokdatabase}.submitted_question_events.recipient_id,
         #{@darmokdatabase}.submitted_question_events.response, #{@darmokdatabase}.submitted_question_events.event_state, 
         #{@darmokdatabase}.submitted_question_events.category, #{@darmokdatabase}.submitted_question_events.additionaldata, 
         #{@darmokdatabase}.submitted_question_events.previous_event_id, #{@darmokdatabase}.submitted_question_events.duration_since_last, #{@darmokdatabase}.submitted_question_events.previous_recipient_id,
         #{@darmokdatabase}.submitted_question_events.previous_initiator_id, #{@darmokdatabase}.submitted_question_events.previous_handling_event_id, #{@darmokdatabase}.submitted_question_events.duration_since_last_handling_event,
         #{@darmokdatabase}.submitted_question_events.previous_handling_event_state, #{@darmokdatabase}.submitted_question_events.previous_handling_recipient_id, #{@darmokdatabase}.submitted_question_events.previous_handling_initiator_id,
         #{@darmokdatabase}.submitted_question_events.previous_category, #{@darmokdatabase}.submitted_question_events.created_at, NOW()       
  FROM  #{@darmokdatabase}.submitted_question_events
  END_SQL
  
  # transferring partially phased out contributing question field, only have question now and getting rid of contributing faqs, pages, etc.
  transfer_contributing_question_id_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.question_events 
  JOIN #{@darmokdatabase}.submitted_question_events ON #{@aae_database}.question_events.id = #{@darmokdatabase}.submitted_question_events.id
  SET #{@aae_database}.question_events.contributing_question_id = #{@darmokdatabase}.submitted_question_events.contributing_content_id
  WHERE #{@darmokdatabase}.submitted_question_events.contributing_content_type = 'SubmittedQuestion'
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_events_transfer_query)
    ActiveRecord::Base.connection.execute(transfer_contributing_question_id_query)
  end
  
  puts " Question Events transferred: #{benchmark.real.round(2)}s"
end

def transfer_responses
  puts 'Transferring responses...'
  responses_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.responses(id, resolver_id, submitter_id, question_id, body, duration_since_last, sent, signature, user_ip, user_agent, referrer, created_at, updated_at)
  SELECT #{@darmokdatabase}.responses.id, #{@darmokdatabase}.responses.resolver_id, #{@darmokdatabase}.responses.submitter_id, #{@darmokdatabase}.responses.submitted_question_id, #{@darmokdatabase}.responses.response, #{@darmokdatabase}.responses.duration_since_last,
         #{@darmokdatabase}.responses.sent, #{@darmokdatabase}.responses.signature, #{@darmokdatabase}.responses.user_ip, #{@darmokdatabase}.responses.user_agent, 
         #{@darmokdatabase}.responses.referrer, #{@darmokdatabase}.responses.created_at, NOW()
  FROM   #{@darmokdatabase}.responses
  END_SQL
  
  # transferring partially phased out contributing question field, only have question now and getting rid of contributing faqs, pages, etc.
  transfer_contributing_question_id_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.responses 
  JOIN #{@darmokdatabase}.responses ON #{@aae_database}.responses.id = #{@darmokdatabase}.responses.id
  SET #{@aae_database}.responses.contributing_question_id = #{@darmokdatabase}.responses.contributing_content_id
  WHERE #{@darmokdatabase}.responses.contributing_content_type = 'SubmittedQuestion'
  END_SQL

  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(responses_transfer_query)
    ActiveRecord::Base.connection.execute(transfer_contributing_question_id_query)
  end
  
  puts " Responses transferred: #{benchmark.real.round(2)}s"
end

# transfer darmok categories to tags (includes both top-level and subcategories)
def transfer_categories_to_tags
  puts 'Transferring categories to tags...'
  # ignore dups
  category_to_tag_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT IGNORE INTO #{@aae_database}.tags(name, created_at)
  SELECT #{@darmokdatabase}.categories.name, #{@darmokdatabase}.categories.created_at 
  FROM   #{@darmokdatabase}.categories
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(category_to_tag_transfer_query)
  end
  
  puts " Categories to tags transferred: #{benchmark.real.round(2)}s"
end

def transfer_personal_taggings
  puts 'Transferring personal taggings...'
  
  # ignore dups
  personal_taggings_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT IGNORE INTO #{@aae_database}.taggings(tag_id, taggable_id, taggable_type, created_at, updated_at)
  SELECT #{@aae_database}.tags.id, #{@aae_database}.users.id, 'User', #{@darmokdatabase}.expertise_areas.created_at, NOW() 
  FROM   #{@aae_database}.tags
  JOIN   #{@darmokdatabase}.categories ON #{@aae_database}.tags.name = #{@darmokdatabase}.categories.name 
  JOIN   #{@darmokdatabase}.expertise_areas ON #{@darmokdatabase}.expertise_areas.category_id = #{@darmokdatabase}.categories.id 
  JOIN   #{@aae_database}.users ON #{@aae_database}.users.id = #{@darmokdatabase}.expertise_areas.user_id
  END_SQL
  
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(personal_taggings_transfer_query)
  end
  
  puts " Personal taggings transferred: #{benchmark.real.round(2)}s"
end

# group tags will be used for expertise area groups, groups from widgets will start with a clean slate.
def transfer_group_tags
  puts 'Transferring expertise group taggings...'
  
  # first, tag each group with their own (top level category) expertise tag from darmok
  expertise_group_top_level_taggings_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.taggings(tag_id, taggable_id, taggable_type, created_at, updated_at)
  SELECT #{@aae_database}.tags.id, #{@aae_database}.groups.id, 'Group', NOW(), NOW() 
  FROM   #{@aae_database}.tags
  JOIN   #{@aae_database}.groups ON #{@aae_database}.groups.name = #{@aae_database}.tags.name
  WHERE  #{@aae_database}.groups.darmok_expertise_id IS NOT NULL
  END_SQL
  
  # next, tag each group with their (sub category) expertise tags from darmok
  expertise_group_subcat_taggings_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.taggings(tag_id, taggable_id, taggable_type, created_at, updated_at)
  SELECT #{@aae_database}.tags.id, #{@aae_database}.groups.id, 'Group', NOW(), NOW() 
  FROM   #{@aae_database}.tags
  JOIN   #{@darmokdatabase}.categories ON #{@darmokdatabase}.categories.name = #{@aae_database}.tags.name
  JOIN   #{@aae_database}.groups ON #{@darmokdatabase}.categories.parent_id = #{@aae_database}.groups.darmok_expertise_id
  WHERE  #{@aae_database}.groups.darmok_expertise_id IS NOT NULL
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(expertise_group_top_level_taggings_transfer_query)
    ActiveRecord::Base.connection.execute(expertise_group_subcat_taggings_transfer_query)
  end
  
  puts " Expertise group taggings transferred: #{benchmark.real.round(2)}s"
end

# transfers the categories and subcategories from questions from darmok
def transfer_question_taggings
  puts 'Transferring question taggings...'
  # ignore dups
  question_tagging_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT IGNORE INTO #{@aae_database}.taggings(tag_id, taggable_id, taggable_type, created_at, updated_at)
  SELECT #{@aae_database}.tags.id, #{@aae_database}.questions.id, 'Question', NOW(), NOW() 
  FROM   #{@aae_database}.tags
  JOIN   #{@darmokdatabase}.categories ON #{@darmokdatabase}.categories.name = #{@aae_database}.tags.name
  JOIN   #{@darmokdatabase}.categories_submitted_questions ON #{@darmokdatabase}.categories_submitted_questions.category_id = #{@darmokdatabase}.categories.id
  JOIN   #{@aae_database}.questions ON #{@aae_database}.questions.id = #{@darmokdatabase}.categories_submitted_questions.submitted_question_id
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_tagging_transfer_query)
  end
  
  puts " Question taggings transferred: #{benchmark.real.round(2)}s"
end

# fill in assigned_group_id for questions that were not from a widget, but had a 
# category (which is now a group), assigned_group_id has already been taken care of for questions
# from a widget as part of the question transfer.
def transfer_question_source
  puts 'Transferring group id references to questions...'
  
  question_group_reference_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.questions 
  JOIN   #{@darmokdatabase}.categories_submitted_questions ON #{@darmokdatabase}.categories_submitted_questions.submitted_question_id = #{@aae_database}.questions.id
  JOIN   #{@darmokdatabase}.categories ON #{@darmokdatabase}.categories_submitted_questions.category_id = #{@darmokdatabase}.categories.id
  JOIN   #{@aae_database}.groups ON #{@aae_database}.groups.darmok_expertise_id = #{@darmokdatabase}.categories.id
  SET    #{@aae_database}.questions.assigned_group_id = #{@aae_database}.groups.id, #{@aae_database}.questions.group_name = #{@aae_database}.groups.name
  WHERE  #{@aae_database}.questions.original_group_id IS NULL AND #{@darmokdatabase}.categories.parent_id IS NULL
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_group_reference_transfer_query)
  end
  
  puts " Group references transferred to questions: #{benchmark.real.round(2)}s"
end

# update all other questions that did not fit into a widget or expertise area
def transfer_misfit_questions_to_groups
  puts 'Updating misfit questions to groupless group...'
  
  question_misfit_update_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.questions
  SET #{@aae_database}.questions.assigned_group_id = #{Group::ORPHAN_GROUP_ID}, #{@aae_database}.questions.group_name = '#{Group::ORPHAN_GROUP_NAME}'
  WHERE #{@aae_database}.questions.assigned_group_id IS NULL AND #{@aae_database}.questions.group_name IS NULL
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_misfit_update_query)
  end
  
  puts " Misfit questions updated: #{benchmark.real.round(2)}s"
end

# transfer all aae preferences from darmok
def transfer_aae_user_prefs
  puts 'Transferring user prefs...'
  
  aae_user_pref_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.user_preferences(id, user_id, name, setting, created_at, updated_at)
  SELECT #{@darmokdatabase}.user_preferences.id, #{@darmokdatabase}.user_preferences.user_id, #{@darmokdatabase}.user_preferences.name, #{@darmokdatabase}.user_preferences.setting, #{@darmokdatabase}.user_preferences.created_at, #{@darmokdatabase}.user_preferences.updated_at
  FROM #{@darmokdatabase}.user_preferences
  WHERE  #{@darmokdatabase}.user_preferences.name IN ('filter.widget.id', 'signature', 'aae_location_only', 'aae_county_only', 'expert.source.filter', 'expert.category.filter', 'expert.county.filter', 'expert.location.filter')
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(aae_user_pref_transfer_query)
  end
  
  puts " AaE user prefs transferred: #{benchmark.real.round(2)}s"  
end

def generate_widget_fingerprint(expertise_area_name, expertise_area_id)
  create_time = Time.now.to_s
  return Digest::SHA1.hexdigest(create_time + expertise_area_name + expertise_area_id.to_s)
end


transfer_accounts
transfer_locations
transfer_counties
transfer_widget_communities_to_groups
transfer_expertise_areas_to_groups
transfer_widget_community_connections_to_group_connections
fill_in_group_connections_for_areas_of_expertise
inactivate_widgets_with_no_active_assignees
transfer_group_events
transfer_questions
transfer_assets
transfer_expertise_locations
transfer_expertise_counties
transfer_question_events
transfer_responses
transfer_categories_to_tags
transfer_personal_taggings
transfer_group_tags
transfer_question_taggings
transfer_question_source
transfer_aae_user_prefs
transfer_widget_group_locations
transfer_misfit_questions_to_groups
