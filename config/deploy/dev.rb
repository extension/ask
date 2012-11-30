set :deploy_to, "/services/aae/"
if(branch = ENV['BRANCH'])
  set :branch, branch
else
  set :branch, 'development'
end
server 'dev.ask.extension.org', :app, :web, :db, :primary => true

if(ENV['REBUILD'] == 'true')
  after "deploy:update_code", "db:rebuild"
end

if(ENV['SEED'] == 'true')
  after "deploy:migrations", "db:seed"
end
