set :deploy_to, "/services/aae/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'staging'
end
server 'demo.ask.extension.org', :app, :web, :db, :primary => true
