set :deploy_to, "/services/aae/"
set :branch, 'master'

server 'ask.extension.org', :app, :web, :db, :primary => true

if(ENV['SEED'] == 'true')
  after "deploy:migrations", "db:seed"
end
