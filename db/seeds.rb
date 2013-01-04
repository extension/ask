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
    INSERT INTO #{@aae_database}.users (id, darmok_id, kind, login, first_name, last_name, public_name, email, title, position_id, location_id, county_id, retired, is_admin, phone_number, time_zone, is_question_wrangler, vacated_aae_at, first_aae_away_reminder, second_aae_away_reminder, current_sign_in_at, last_sign_in_at, created_at, updated_at)
    SELECT #{@darmokdatabase}.accounts.id, #{@darmokdatabase}.accounts.id, #{@darmokdatabase}.accounts.type, #{@darmokdatabase}.accounts.login, #{@darmokdatabase}.accounts.first_name, #{@darmokdatabase}.accounts.last_name, NULL, 
           #{@darmokdatabase}.accounts.email, #{@darmokdatabase}.accounts.title, #{@darmokdatabase}.accounts.position_id, #{@darmokdatabase}.accounts.location_id, #{@darmokdatabase}.accounts.county_id, #{@darmokdatabase}.accounts.retired,
           #{@darmokdatabase}.accounts.is_admin, #{@darmokdatabase}.accounts.phonenumber, #{@darmokdatabase}.accounts.time_zone, #{@darmokdatabase}.accounts.is_question_wrangler, #{@darmokdatabase}.accounts.vacated_aae_at,
           #{@darmokdatabase}.accounts.first_aae_away_reminder, #{@darmokdatabase}.accounts.second_aae_away_reminder, #{@darmokdatabase}.accounts.last_login_at, #{@darmokdatabase}.accounts.last_login_at, #{@darmokdatabase}.accounts.created_at, NOW() 
    FROM   #{@darmokdatabase}.accounts
  END_SQL

  # erase darmok_id for PublicUser accounts
  # this is simpler than a mysql IF statement above
  remove_darmok_association_query = "UPDATE #{@aae_database}.users SET darmok_id = NULL where kind = 'PublicUser'"
  
  # transfer data for away status (field has changed from a responder to a away flag)
  # default for this field is false
  # also all public accounts should have the away field set to true, they were set to false in darmok
  transfer_aae_responder_query = <<-END_SQL.gsub(/\s+/, " ").strip
    UPDATE #{@aae_database}.users
    JOIN #{@darmokdatabase}.accounts ON #{@aae_database}.users.id = #{@darmokdatabase}.accounts.id
    SET #{@aae_database}.users.away = 1
    WHERE #{@darmokdatabase}.accounts.aae_responder = 0 OR #{@aae_database}.users.kind = 'PublicUser'
  END_SQL

  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(account_insert_query)
    ActiveRecord::Base.connection.execute(remove_darmok_association_query)
    ActiveRecord::Base.connection.execute(transfer_aae_responder_query)
  end
  
  puts " Accounts transferred : #{benchmark.real.round(2)}s"
  
  authmap_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.authmaps (user_id, authname, source, created_at, updated_at) 
    SELECT #{@aae_database}.users.id, CONCAT('https://people.extension.org/',#{@darmokdatabase}.accounts.login), 'people', #{@darmokdatabase}.accounts.created_at, NOW()
    FROM #{@aae_database}.users,#{@darmokdatabase}.accounts
    WHERE #{@aae_database}.users.id = #{@darmokdatabase}.accounts.id
    AND #{@darmokdatabase}.accounts.type = 'User'
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
  # also preserve old widget id here just in case we ever should need it
  group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (id, name, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_id, old_widget_url, group_notify, created_at, updated_at)
    SELECT #{@darmokdatabase}.communities.id, #{@darmokdatabase}.widgets.name, #{@darmokdatabase}.communities.active, #{@darmokdatabase}.communities.created_by,
           #{@darmokdatabase}.widgets.fingerprint, #{@darmokdatabase}.widgets.upload_capable, #{@darmokdatabase}.widgets.show_location, #{@darmokdatabase}.widgets.enable_tags, #{@darmokdatabase}.widgets.location_id,
           #{@darmokdatabase}.widgets.county_id, #{@darmokdatabase}.widgets.id, #{@darmokdatabase}.widgets.old_widget_url, #{@darmokdatabase}.widgets.group_notify, #{@darmokdatabase}.widgets.created_at, NOW()
    FROM #{@darmokdatabase}.communities
    JOIN #{@darmokdatabase}.widgets ON #{@darmokdatabase}.widgets.id = #{@darmokdatabase}.communities.widget_id
  END_SQL
  
  # we need to add the Question Wrangler community to groups which is a special case. the question wrangler community does not have a widget
  # and they're not a selectable area of expertise, but will be a formal and emphasized group in this AaE application and will have a widget.
  wrangler_group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (id, name, widget_public_option, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_url, group_notify, created_at, updated_at)
    SELECT #{@darmokdatabase}.communities.id, #{@darmokdatabase}.communities.name, true, #{@darmokdatabase}.communities.active, #{@darmokdatabase}.communities.created_by,
           NULL, true, true, false, NULL, NULL, NULL, true, #{@darmokdatabase}.communities.created_at, NOW()
    FROM #{@darmokdatabase}.communities
    WHERE #{@darmokdatabase}.communities.name = 'eXtension Question Wranglers'
  END_SQL
  
  ## While we're inserting groups here, let's add a generic group that will be assigned questions with unaffiliated groups
  orphan_group_insert_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.groups (id, name, description, active, created_by, widget_fingerprint, widget_upload_capable, widget_show_location, widget_enable_tags, widget_location_id, widget_county_id, old_widget_url, group_notify, created_at, updated_at)
    VALUES (1, 'Orphan Group', 'Group that holds orphaned questions that have no other group assignment.', true, #{User.system_user_id}, NULL, false, false, false, NULL, NULL, NULL, false, NOW(), NOW()) 
  END_SQL

  ## take the groups with "test" in the name and flag them as test groups
  test_group_update_query = "Update #{@aae_database}.groups set is_test = 1 where name like '%test%'"

  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(group_insert_query)
    ActiveRecord::Base.connection.execute(wrangler_group_insert_query)
    ActiveRecord::Base.connection.execute(orphan_group_insert_query)
    ActiveRecord::Base.connection.execute(test_group_update_query)
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
  WHERE #{@aae_database}.groups.darmok_expertise_id IS NULL and #{@aae_database}.groups.id != 1
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
  WHERE #{@darmokdatabase}.activities.activitycode IN (201, 203, 212, 214, 110) AND #{@aae_database}.groups.darmok_expertise_id IS NULL
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
  INSERT INTO #{@aae_database}.questions(id, current_resolver_id, status, body, title, is_private, is_private_reason, assignee_id, assigned_group_id, duplicate, external_app_id, submitter_email, resolved_at, question_updated_at, current_response, question_fingerprint, submitter_firstname, submitter_lastname, county_id, location_id, spam_legacy, user_ip, user_agent, referrer, status_state, zip_code, original_group_id, submitter_id, last_assigned_at, last_opened_at, is_api, created_at, updated_at)
  SELECT #{@darmokdatabase}.submitted_questions.id, #{@darmokdatabase}.submitted_questions.resolved_by, #{@darmokdatabase}.submitted_questions.status, #{@darmokdatabase}.submitted_questions.asked_question,
         null, true, 2, #{@darmokdatabase}.submitted_questions.user_id, #{@darmokdatabase}.communities.id, #{@darmokdatabase}.submitted_questions.duplicate, #{@darmokdatabase}.submitted_questions.external_app_id, #{@darmokdatabase}.submitted_questions.submitter_email,
         #{@darmokdatabase}.submitted_questions.resolved_at, #{@darmokdatabase}.submitted_questions.question_updated_at, #{@darmokdatabase}.submitted_questions.current_response,
         #{@darmokdatabase}.submitted_questions.question_fingerprint, #{@darmokdatabase}.submitted_questions.submitter_firstname, #{@darmokdatabase}.submitted_questions.submitter_lastname,
         #{@darmokdatabase}.submitted_questions.county_id, #{@darmokdatabase}.submitted_questions.location_id, #{@darmokdatabase}.submitted_questions.spam, #{@darmokdatabase}.submitted_questions.user_ip, #{@darmokdatabase}.submitted_questions.user_agent, 
         #{@darmokdatabase}.submitted_questions.referrer, #{@darmokdatabase}.submitted_questions.status_state, #{@darmokdatabase}.submitted_questions.zip_code,
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
  end
  
  puts " Questions transferred: #{benchmark.real.round(2)}s"
end

def transfer_assets
  puts 'Transferring assets...'
  question_asset_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.assets(id,type, assetable_id, assetable_type, attachment_file_name, attachment_content_type, attachment_file_size, attachment_updated_at, created_at, updated_at)
  SELECT #{@darmokdatabase}.file_attachments.id,'Question::Image', #{@darmokdatabase}.file_attachments.submitted_question_id, 'Question', #{@darmokdatabase}.file_attachments.attachment_file_name, #{@darmokdatabase}.file_attachments.attachment_content_type,
         #{@darmokdatabase}.file_attachments.attachment_file_size, #{@darmokdatabase}.file_attachments.attachment_updated_at, #{@darmokdatabase}.file_attachments.created_at, NOW()
  FROM   #{@darmokdatabase}.file_attachments
  WHERE  #{@darmokdatabase}.file_attachments.submitted_question_id IS NOT NULL AND #{@darmokdatabase}.file_attachments.response_id IS NULL
  END_SQL
  
  response_asset_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.assets(id,type, assetable_id, assetable_type, attachment_file_name, attachment_content_type, attachment_file_size, attachment_updated_at, created_at, updated_at)
  SELECT #{@darmokdatabase}.file_attachments.id,'Response::Image', #{@darmokdatabase}.file_attachments.response_id, 'Response', #{@darmokdatabase}.file_attachments.attachment_file_name, #{@darmokdatabase}.file_attachments.attachment_content_type,
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

# deal with spam questions from old db and setting fields for old rejected questions as well, spam is now a subset of rejected.
def transfer_spam_and_rejected_data
  puts 'Transferring spam and rejected data...'
  # we need to update the questions and mark the is_private_reason for spam and rejected questions
  # just note that is_private has already been taking care of in the transfer questions insert question, which sets all 
  # legacy questions to private.
  benchmark = Benchmark.measure do
    spam_questions = Question.where(:spam_legacy => true)
     spam_questions.each do |sq|
      sq.update_attributes(:status => Question::REJECTED_TEXT, :status_state => Question::STATUS_REJECTED, :is_private_reason => Question::PRIVACY_REASON_REJECTED, :current_response => 'Spam')
      last_spam_question_event = QuestionEvent.find(:first, :conditions => {:question_id => sq.id, :event_state => 3}, :order => "created_at DESC")
      sq.update_attributes(:resolved_at => last_spam_question_event.created_at, :current_resolver_id => last_spam_question_event.initiated_by_id) if last_spam_question_event.present?
    end
    # search for rejected questions where spam = false, b/c spam questions are now a subset of rejected questions and they've been handled above
    rejected_questions = Question.where({:status_state => Question::STATUS_REJECTED, :spam_legacy => false})
    rejected_questions.each do |rq|
      rq.update_attribute(:is_private_reason, Question::PRIVACY_REASON_REJECTED)
    end
  end
  
  # update for question_events marked as spam in the old system
  # this will transition to rejected questions (a subset of rejected.)
  # even though marking things as rejected is a handling event, and spam should technically be,
  # the marking of spam questions was not recorded as a handling event in darmok, so for the 
  # question events for spam, we cannot take and put handling duration timestamps and last handling event id's for 
  # the question events that referenced these spam question events. that data just will not be there for the old spam 
  # questions, but it never was to begin with in darmok.
  spam_events = QuestionEvent.where({:event_state => 3})
  spam_events.each do |se|
    se.update_attributes(:response => 'Spam', :event_state => QuestionEvent::REJECTED)
  end
  
  # update for question_events marked as not spam in the old system, this will transition to reactivated.
  non_spam_events = QuestionEvent.where({:event_state => 4})
  non_spam_events.each do |nse|
    nse.update_attribute(:event_state, QuestionEvent::REACTIVATE)
  end
  
  puts " Spam and Rejected Data transferred: #{benchmark.real.round(2)}s"
end

def transfer_responses
  puts 'Transferring responses...'
  responses_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  INSERT INTO #{@aae_database}.responses(id, resolver_id, submitter_id, question_id, body, sent, signature, user_ip, user_agent, referrer, created_at, updated_at)
  SELECT #{@darmokdatabase}.responses.id, #{@darmokdatabase}.responses.resolver_id, #{@darmokdatabase}.responses.submitter_id, #{@darmokdatabase}.responses.submitted_question_id, #{@darmokdatabase}.responses.response,
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


  # set the initial_response_id and initial_response_time
  set_response_time_query =  <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE questions, 
  (select id,question_id,created_at from responses 
   where created_at = (select min(created_at) from responses min_responses where min_responses.resolver_id is NOT NULL and responses.question_id = min_responses.question_id) 
   and id = (select min(id) from responses min_responses where min_responses.resolver_id is NOT NULL and responses.question_id = min_responses.question_id)
  ) as first_response 
  SET questions.initial_response_id = first_response.id, questions.initial_response_time = TIMESTAMPDIFF(SECOND,questions.created_at,first_response.created_at)
  WHERE questions.id = first_response.question_id
  END_SQL

  # fix the response times for all questions resolved prior to 2009-10-13 because the response created_at data is flawed prior to that date
  # this still leaves ~14 records in limbo, but should make things more accurate
  fix_response_time_query = 'UPDATE questions SET initial_response_time = TIMESTAMPDIFF(SECOND,questions.created_at,questions.resolved_at) WHERE DATE(questions.resolved_at) <= \'2009-10-13\''

  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(responses_transfer_query)
    ActiveRecord::Base.connection.execute(transfer_contributing_question_id_query)
    ActiveRecord::Base.connection.execute(set_response_time_query)
    ActiveRecord::Base.connection.execute(fix_response_time_query)
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
  SET    #{@aae_database}.questions.assigned_group_id = #{@aae_database}.groups.id
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
  SET #{@aae_database}.questions.assigned_group_id = #{Group::ORPHAN_GROUP_ID}
  WHERE #{@aae_database}.questions.assigned_group_id IS NULL 
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(question_misfit_update_query)
  end
  
  puts " Misfit questions updated: #{benchmark.real.round(2)}s"
end

# transfer aae preferences from darmok
# the aae listview filtering preferences will not be transferring over as many of them do not make sense because of datatype changes, and 
# do not make sense with the new way we're doing filtering, plus this is a new system and it's reasonable that people can reset their listview preferences here
def transfer_aae_user_prefs
  puts 'Transferring user prefs...'
  
  aae_signature_pref_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.users 
  JOIN #{@darmokdatabase}.user_preferences ON #{@aae_database}.users.id = #{@darmokdatabase}.user_preferences.user_id
  SET #{@aae_database}.users.signature = #{@darmokdatabase}.user_preferences.setting
  WHERE #{@darmokdatabase}.user_preferences.name = 'signature'
  END_SQL
  
  # default for routing_instructions is 'anywhere'
  
  aae_location_only_pref_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.users
  JOIN #{@darmokdatabase}.user_preferences ON #{@aae_database}.users.id = #{@darmokdatabase}.user_preferences.user_id
  SET #{@aae_database}.users.routing_instructions = 'locations_only' 
  WHERE #{@darmokdatabase}.user_preferences.name = 'aae_location_only'
  END_SQL
  
  aae_county_only_pref_transfer_query = <<-END_SQL.gsub(/\s+/, " ").strip
  UPDATE #{@aae_database}.users
  JOIN #{@darmokdatabase}.user_preferences ON #{@aae_database}.users.id = #{@darmokdatabase}.user_preferences.user_id
  SET #{@aae_database}.users.routing_instructions = 'counties_only' 
  WHERE #{@darmokdatabase}.user_preferences.name = 'aae_county_only'
  END_SQL
  
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(aae_signature_pref_transfer_query)
    ActiveRecord::Base.connection.execute(aae_location_only_pref_transfer_query)
    ActiveRecord::Base.connection.execute(aae_county_only_pref_transfer_query)
  end
  
  puts " AaE user prefs transferred: #{benchmark.real.round(2)}s"  
end

def generate_widget_fingerprint(expertise_area_name, expertise_area_id)
  create_time = Time.now.to_s
  return Digest::SHA1.hexdigest(create_time + expertise_area_name + expertise_area_id.to_s)
end

def transfer_geo_names
  puts 'Transferring Geonames...'

  geo_names_query = "INSERT INTO #{@aae_database}.geo_names  SELECT * FROM #{@darmokdatabase}.geo_names;"
  benchmark = Benchmark.measure do
    ActiveRecord::Base.connection.execute(geo_names_query)
  end
  
  puts " Geonames transferred: #{benchmark.real.round(2)}s"
end

def create_notification_prefs_for_groups_with_notifications
  puts 'Creating default notification prefs'
  benchmark = Benchmark.measure do
    Group.where(:group_notify => true).each do |group|
      group.joined.each do |group_member|
        Preference.create(:prefable_id => group_member.id, 
                          :group_id => group.id, 
                          :prefable_type => 'User', 
                          :classification => 'notification', 
                          :name => Preference::NOTIFICATION_INCOMING, 
                          :datatype => 'Boolean', 
                          :value => '1', 
                          :created_at => Time.now, 
                          :updated_at => Time.now)
      end
    end
  end
  puts " Notification prefs transferred: #{benchmark.real.round(2)}s"
end

def create_default_daily_summary_prefs_for_group_leaders
  puts 'Creating default daily summary prefs for group leaders'
  benchmark = Benchmark.measure do
    GroupConnection.where(:connection_type => 'leader').each do |connection|
      Preference.create_or_update(connection.user, Preference::NOTIFICATION_DAILY_SUMMARY, true, connection.group.id) #leaders are opted into daily summaries / escalations
    end
  end
  puts " Daily Summary prefs transferred: #{benchmark.real.round(2)}s"
end

def seed_evaluation_questions
  puts 'Seeding evaluation questions'

  EvaluationQuestion.create(prompt: "The question you asked was...",
                            responsetype: EvaluationQuestion::SCALE,
                            questionorder: 1,
                            responses: ['a personal curiousity that was not too important','critically important to me'],
                            range_start: 1,
                            range_end: 5,
                            creator_id: User.system_user_id)

  EvaluationQuestion.create(prompt: "The response given by the Ask an Expert service to my question...",
                            responsetype: EvaluationQuestion::SCALE,
                            questionorder: 2,
                            responses: ['did not answer my question','completely answered my question'],
                            range_start: 1,
                            range_end: 5,
                            creator_id: User.system_user_id)

  EvaluationQuestion.create(prompt: "The advice that was offered was...",
                            responsetype: EvaluationQuestion::SCALE,
                            questionorder: 3,
                            responses: ['too complex','too simplistic'],
                            range_start: 1,
                            range_end: 5,
                            creator_id: User.system_user_id)

  EvaluationQuestion.create(prompt: "In this story, the need for an answer was of...",
                            responsetype: EvaluationQuestion::SCALE,
                            questionorder: 4,
                            responses: ['little economic consequence to me','of significant economic concern to me'],
                            range_start: 1,
                            range_end: 5,
                            creator_id: User.system_user_id)

  EvaluationQuestion.create(prompt: "If the answer had an economic benefit to you, what would you estimate that benefit to be in U.S. dollars?",
                            responsetype: EvaluationQuestion::OPEN_DOLLAR_VALUE,
                            questionorder: 5,
                            creator_id: User.system_user_id)

  EvaluationQuestion.create(prompt: "My expectation for the time it would take for me to receive a  response to my question was (in days):",
                            responsetype: EvaluationQuestion::OPEN_TIME_VALUE,
                            questionorder: 6,
                            creator_id: User.system_user_id)
end

def seed_demographic_questions
  puts 'Seeding demographic questions'

  DemographicQuestion.create(prompt: "Your gender:",
                             responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                             questionorder: 1,
                             responses: ['Female','Male'],
                             creator_id: User.system_user_id)

  DemographicQuestion.create(prompt: "Your age:",
                             responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                             questionorder: 2,
                             responses: ['18-29','30-49','50-64','65+'],
                             creator_id: User.system_user_id)

  DemographicQuestion.create(prompt: "Which of the following best describes your formal education:",
                             responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                             questionorder: 3,
                             responses: ['Less than high school','High school graduate/GED','Some college','College graduate','Master degree','Doctorate/Law degree'],
                             creator_id: User.system_user_id)

  DemographicQuestion.create(prompt: "Your yearly family income is:",
                             responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                             questionorder: 4,
                             responses: ['Less than $25K','$25K - $49K','$50K - $74K','$75K - $99K','Greater than $100K','Decline to answer'],
                             creator_id: User.system_user_id)

  DemographicQuestion.create(prompt: "Are you of Hispanic, Latino or Spanish origin?",
                             responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                             questionorder: 5,
                             responses: ['yes, Mexican, Mexican American, Chicano','yes, Puerto Rican','yes, Cuban','no, not Hispanic, Latino, or Spanish origin','don\'t know'],
                             creator_id: User.system_user_id)

  DemographicQuestion.create(prompt: "What race do you consider yourself to be?",
                             responsetype: DemographicQuestion::MULTIPLE_CHOICE,
                             questionorder: 6,
                             responses: ['White','Black/African American','American Indian or Alaska Native','Asian Indian',
                                         'Chinese','Japanese','Filipino','Korean','Vietnamese','Some other Asian','Native Hawaiian',
                                         'Samoan','Guamanian or Chamorro','some other Pacific Islander','other race','don\'t know'],
                             creator_id: User.system_user_id)

end


# triggers the html sanitization
def cleanup_questions
  puts 'Cleaning up any html in questions'
  benchmark = Benchmark.measure do
    Question.find_each do |q|
      scrubbed = q.cleanup_html(q.body)
      if(scrubbed != q.body)
        q.update_column(:body, scrubbed)
      end
    end
  end
  puts " Finished!: #{benchmark.real.round(2)}s"
end

# triggers the html sanitization
def cleanup_question_event_responses
  puts 'Cleaning up any html in question events'
  benchmark = Benchmark.measure do
    QuestionEvent.where('response IS NOT NULL').find_each do |qe|
      scrubbed = qe.cleanup_html(qe.response)
      if(scrubbed != qe.response)
        qe.update_column(:response, qe.response)
      end
    end
  end
  puts " Finished!: #{benchmark.real.round(2)}s"
end

# triggers the html sanitization
def cleanup_responses
  puts 'Cleaning up any html in responses'
  benchmark = Benchmark.measure do
    Response.skip_callback(:save,:after,:perform_index_tasks)
    Response.find_each do |r|
      scrubbed = r.cleanup_html(r.body)
      if(scrubbed != r.body)
        r.update_column(:body, scrubbed)
      end
    end
  end
  puts " Finished!: #{benchmark.real.round(2)}s"
end

def reindex_searchable_objects
  [Question,Group,User].each do |class_object|
    puts "Re-indexing #{class_object.name.pluralize}"
    benchmark = Benchmark.measure do
      class_object.reindex
    end
    puts " Finished!: #{benchmark.real.round(2)}s"  
  end
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
transfer_geo_names
create_notification_prefs_for_groups_with_notifications
create_default_daily_summary_prefs_for_group_leaders
transfer_spam_and_rejected_data
seed_evaluation_questions
seed_demographic_questions
# cleanup_questions
# cleanup_question_event_responses
# cleanup_responses
# reindex_searchable_objects
