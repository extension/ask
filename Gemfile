source 'http://rubygems.org'
source 'https://engineering.extension.org/rubygems'

gem 'rails', "3.2.18"

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

gem 'sitemap_generator'

# authentication
gem 'devise', "~> 1.5.1"
gem 'omniauth-facebook'
gem 'omniauth-openid'
gem 'omniauth-twitter'

# oauth integration
gem 'omniauth', "~> 1.0"

# feed retrieval and parsing
# force curb to 0.7.15 to avoid a constant warning
gem "curb", "0.7.15"
gem "feedzirra", "0.1.2"

# pagination
gem 'kaminari'

# revision history
gem 'paper_trail', '~> 2'

# diffs
gem 'diffy'

# server settings
gem "rails_config"

# exception notification
gem 'airbrake'

# comment and threaded discussion support
gem 'ancestry'

# auto strip spaces out of attributes of models
gem "auto_strip_attributes", "~> 2.0"

# readability port
gem "ruby-readability", "~> 0.2.4" ,:require => 'readability'

# html scrubbing
gem "loofah"

# htmlentities conversion
gem "htmlentities"

# search on solr
gem "sunspot_rails", "~> 1.3.0"

# used to post-process mail to convert styles to inline
gem "csspool"
gem "inline-style", "0.5.2ex"

# auto_link replacement
gem "rinku", :require => 'rails_rinku'

# require sunspot_solr for test and dev
group :test, :development do
  gem 'sunspot_solr', "~> 1.3.0"
end

# sidekiq - must come before delayed job in the gemfile
gem 'sidekiq', "~> 2.17"

# delayed_job
gem "delayed_job"
gem 'delayed_job_active_record'
gem "daemons"

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

group :development do
  # require the powder gem
  gem 'powder'
  # rails3 compatible generators
  gem "rails3-generators"
  gem 'capistrano'
  gem 'capatross'
  gem 'quiet_assets'
  gem 'pry'
  gem 'net-http-spy'

  # pretty error handling
  #gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
  # gem 'shoulda', '>= 3.0.0.beta'
  gem 'factory_girl_rails'
end
