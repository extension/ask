set :deploy_to, "/services/ask/"
set :branch, 'master'
set :vhost, 'ask.extension.org'
server vhost, :app, :web, :db, :primary => true
