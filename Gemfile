source 'http://rubygems.org'

gem 'rails', "3.2.22.5"

# Gems used only for assets and not required
# in production environments by default.
# speed up sppppppprooooockets
gem 'turbo-sprockets-rails3'
group :assets do
  gem 'sass-rails', "~> 3.2.4"
  gem 'coffee-rails', "~> 3.2.2"
  gem 'uglifier', '>= 1.0.3'
  gem 'jqtools-rails'
end

# xml parsing
gem 'nokogiri'

# jquery
gem 'jquery-rails'

# bootstrap in sass in rails
gem 'bootstrap-sass', '~> 3.1.1'
# wysihtml5 + bootstrap + asset pipeline
gem 'bootstrap-wysihtml5-rails'

# select2 asset packaging - used for filter interfaces
gem "select2-rails"

# jqplot
gem 'outfielding-jqplot-rails'

# replaces glyphicons
gem 'font-awesome-rails'

# storage
gem 'mysql2'

# image upload
gem "paperclip", "~> 3.0"

# image processing
gem 'rmagick'

# ip to geo mapping
gem 'geocoder'
gem 'geoip'

# authentication
gem 'devise', "~> 1.5.1"
gem 'omniauth-facebook'
gem 'omniauth-openid'
gem 'omniauth-twitter'

# oauth integration
gem 'omniauth', "~> 1.0"

# pagination
gem 'kaminari'

# revision history
gem 'paper_trail', '~> 2', :source => 'http://rubygems.org/'

# diffs
gem 'diffy'

# server settings
gem "rails_config"

# exception notification
gem 'honeybadger'

# auto strip spaces out of attributes of models
gem "auto_strip_attributes", "~> 2.0"

# html scrubbing
gem "loofah"

# htmlentities conversion
gem "htmlentities"

# search on solr
gem "sunspot_rails"
# rake progress
gem "progress_bar"

# used to post-process mail to convert styles to inline
gem "csspool"
gem "inline-style", "0.5.2ex", source: 'https://engineering.extension.org/rubygems'


# auto_link replacement
gem "rinku", :require => 'rails_rinku'

# require sunspot_solr for test and dev
group :test, :development do
  gem 'sunspot_solr'
end

# sidekiq - must come before delayed job in the gemfile
gem 'sidekiq', '< 4'
gem 'sinatra'

# delayed_job
# gem "delayed_job"
# gem 'delayed_job_active_record'
# gem "daemons"

# tropo - sms messages
# gem "tropo-webapi-ruby"

# command line scripts
gem "thor"

# anti-spam test
gem 'rakismet'

# memcached
gem 'dalli'

# useragent analysis
gem 'useragent'

# catch rack errors
gem 'rack-robustness'

# terse logging
gem 'lograge'

# remove emoji
gem 'demoji'

# additional help in blocking apps
gem 'rack-attack'

# Ruby 2.2 requirement
gem 'test-unit'

# monitoring
gem 'scout_apm'

group :development do
  # require the powder gem
  gem 'powder'
  # rails3 compatible generators
  gem "rails3-generators"
  gem 'capistrano', '~> 2.15'
  gem 'capatross'
  gem 'quiet_assets'
  gem 'pry'
  gem 'net-http-spy'

  # pretty error handling
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'active_record_query_trace'
end
