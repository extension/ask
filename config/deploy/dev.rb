set :deploy_to, "/services/ask/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'master'
end
set :vhost, 'dev-ask.awsi.extension.org'
server vhost, :app, :web, :db, :primary => true
