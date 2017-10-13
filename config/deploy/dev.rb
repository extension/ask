set :deploy_to, "/services/ask/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-ask.extension.org'
set :deploy_server, 'dev-ask.awsi.extension.org'
server deploy_server, :app, :web, :db, :primary => true
