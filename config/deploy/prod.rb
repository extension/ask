set :deploy_to, "/services/ask/"
set :branch, 'master'
set :vhost, 'ask.extension.org'
set :deploy_server, 'ask.awsi.extension.org'
server deploy_server, :app, :web, :db, :primary => true
