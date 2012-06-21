set :deploy_to, "/services/aae/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'development'
end
server 'dev.ask.extension.org', :app, :web, :db, :primary => true
