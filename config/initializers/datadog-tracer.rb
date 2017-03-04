Rails.configuration.datadog_trace = {
  enabled: (!Settings.app_location.nil? and Settings.app_location == 'production'),
  auto_instrument: (!Settings.app_location.nil?  and Settings.app_location == 'production'),
  auto_instrument_redis: (!Settings.sidekiq_enabled.nil? and Settings.sidekiq_enabled),
  default_service: 'ask'
}
