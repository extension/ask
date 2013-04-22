set :stages, %w(prod dev)
set :default_stage, "dev"
require 'capistrano/ext/multistage'
require 'capatross'
require "bundler/capistrano"
require "delayed/recipes"
require './config/boot'
require 'airbrake/capistrano'

TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'yes','YES','y','Y']
FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE','no','NO','n','N']
 
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

before "deploy", "deploy:checks:git_push"
if(TRUE_VALUES.include?(ENV['MIGRATE']))
  before "deploy", "deploy:web:disable"
  after "deploy:update_code", "deploy:update_maint_msg"
  after "deploy:update_code", "deploy:link_and_copy_configs"
  after "deploy:update_code", "deploy:cleanup"
  after "deploy:update_code", "deploy:migrate"
  after "deploy", "deploy:web:enable"
else
  before "deploy", "deploy:checks:git_migrations"
  after "deploy:update_code", "deploy:update_maint_msg"
  after "deploy:update_code", "deploy:link_and_copy_configs"
  after "deploy:update_code", "deploy:cleanup"
end

# delayed job
before "deploy", "delayed_job:stop"
after "deploy:link_and_copy_configs", "delayed_job:start"
after "deploy:restart", "delayed_job:restart"

namespace :deploy do
  
  # Override default restart task
  desc "Restart passenger"
  task :restart, :roles => :app do
    run "touch #{current_path}/tmp/restart.txt"
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
    ln -nfs #{shared_path}/config/scout_rails.yml #{release_path}/config/scout_rails.yml &&
    ln -nfs #{shared_path}/config/sunspot.yml #{release_path}/config/sunspot.yml &&
    ln -nfs #{shared_path}/config/robots.txt #{release_path}/public/robots.txt &&
    ln -nfs #{shared_path}/sitemaps #{release_path}/public/sitemaps   
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
  
  namespace :checks do
    desc "check to see if the local branch is ahead of the upstream tracking branch"
    task :git_push, :roles => :app do
      branch_status = `git status --branch --porcelain`.split("\n")[0]

      if(branch_status =~ %r{^## (\w+)\.\.\.([\w|/]+) \[(\w+) (\d+)\]})
        if($3 == 'ahead')
          logger.important "Your local #{$1} branch is ahead of #{$2} by #{$4} commits. You probably want to push these before deploying."
          $stdout.puts "Do you want to continue deployment? (Y/N)"
          unless (TRUE_VALUES.include?($stdin.gets.strip))
            logger.important "Stopping deployment by request!"
            exit(0)
          end
        end
      end         
    end

    desc "check to see if there are migrations in origin/branch "
    task :git_migrations, :roles => :app do
      diff_stat = `git --no-pager diff --shortstat #{current_revision} #{branch} db/migrate`.strip

      if(!diff_stat.empty?)
        diff_files = `git --no-pager diff --summary #{current_revision} #{branch} db/migrate`
        logger.info "Your local #{branch} branch has migration changes and you did not specify MIGRATE=true for this deployment"
        logger.info "#{diff_files}"
      end         
    end    
  end
end

namespace :db do
  desc "drop the database, create the database, run migrations, seed"
  task :rebuild, :roles => :db, :only => {:primary => true} do
    run "cd #{release_path} && #{rake} db:demo_rebuild RAILS_ENV=production"
  end
  
  desc "reload the database with seed data"
    task :seed do
      run "cd #{release_path} && #{rake} db:seed RAILS_ENV=production"
    end
end  

