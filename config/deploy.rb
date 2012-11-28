set :stages, %w(demo dev)
set :default_stage, "dev"
require 'capistrano/ext/multistage'
require 'capatross'
require "bundler/capistrano"
require "delayed/recipes"
require './config/boot'
require 'airbrake/capistrano'
 
set :application, "aae"
set :repository,  "git@github.com:extension/aae.git"
set :scm, "git"
set :user, "pacecar"
set :use_sudo, false
set :keep_releases, 5
ssh_options[:forward_agent] = true
set :port, 24
set :bundle_flags, ''
set :bundle_dir, ''
set :rails_env, "production" #added for delayed job  

before "deploy", "deploy:web:disable"
after "deploy:update_code", "deploy:update_maint_msg"
after "deploy:update_code", "deploy:link_and_copy_configs"
after "deploy:update_code", "deploy:cleanup"
after "deploy", "deploy:web:enable"
# delayed job
after "deploy:stop",    "delayed_job:stop"
after "deploy:start",   "delayed_job:start"
after "deploy:restart", "delayed_job:restart"

namespace :deploy do
  
  desc "Deploy the #{application} application with migrations"
  task :default, :roles => :app do
        
    # Invoke deployment with migrations
    deploy.migrations
  end
  
  # Override default restart task
  desc "Restart passenger"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  # bundle installation in the system-wide gemset
  desc "runs bundle update"
  task :bundle_install do
    run "cd #{release_path} && bundle install"
  end
    
  desc "Update maintenance mode page/graphics (valid after an update code invocation)"
  task :update_maint_msg, :roles => :app do
     invoke_command "cp -f #{release_path}/public/maintenancemessage.html #{shared_path}/system/maintenancemessage.html"
  end
  
  # Link up various configs (valid after an update code invocation)
  task :link_and_copy_configs, :roles => :app do
    run <<-CMD
    rm -rf #{release_path}/config/database.yml && 
    ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml &&
    ln -nfs #{shared_path}/config/settings.local.yml #{release_path}/config/settings.local.yml &&
    ln -nfs #{shared_path}/config/sunspot.yml #{release_path}/config/sunspot.yml
    CMD
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
  # Override default web enable/disable tasks
  namespace :web do
      
    desc "Put Apache in maintenancemode by touching the system/maintenancemode file"
    task :disable, :roles => :app do
      invoke_command "touch #{shared_path}/system/maintenancemode"
    end
  
    desc "Remove Apache from maintenancemode by removing the system/maintenancemode file"
    task :enable, :roles => :app do
      invoke_command "rm -f #{shared_path}/system/maintenancemode"
    end
    
  end  
end

namespace :db do
  desc "drop the database, create the database, run migrations, seed"
  task :rebuild, :roles => :db, :only => {:primary => true} do
    run "cd #{release_path} && #{rake} db:demo_rebuild RAILS_ENV=production"
  end
end  

