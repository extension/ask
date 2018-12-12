class Rack::Attack

  # blacklist some google appengine requests for now
  blacklist('block some google appengine requests') do |req|
    regex = Regexp.new(Settings.block_user_agent_regex)
    req.user_agent =~ regex
  end

  blacklist('Additional honey pot') do |req|
  	# req.post? && !req.params['ask_expert_required'].blank?
  	# req.post? && !req.params['ask_expert_required'] #verified...this stops submission if ask_expert_required not present (I'm just removing the div id="ask_expert_required_18804045" from the view)
  	req.post? && (!req.params['ask_expert_required'].blank? || !req.params['ask_expert_required'])
	end

end

# Rack::Attack.blacklisted_response = lambda do |env|
#   # Using 503 because it may make attacker think that they have successfully
#   # DOSed the site. Rack::Attack returns 403 for blacklists by default
#   [ 403, {}, ['Blocked']]
# end
