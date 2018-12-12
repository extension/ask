class Rack::Attack

  # blacklist some google appengine requests for now
  blacklist('block some google appengine requests') do |req|
    regex = Regexp.new(Settings.block_user_agent_regex)
    req.user_agent =~ regex
  end

  blacklist('Additional honey pot') do |req|
  	#if params['ask_expert_required'] is blank OR if the param does not exist in the question form 
  	#then we block
  	req.post? && (!req.params['ask_expert_required'].blank? || !req.params['ask_expert_required'])
	end

end

# Rack::Attack.blacklisted_response = lambda do |env|
#   # Using 503 because it may make attacker think that they have successfully
#   # DOSed the site. Rack::Attack returns 403 for blacklists by default
#   [ 403, {}, ['Blocked']]
# end
