namespace :db do
  desc "(local dev) Drop:all, create, migrate, seed the database"
  task :rebuild => ['db:drop:all', 'db:create', 'db:migrate', 'db:seed']  
end
