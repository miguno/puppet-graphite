class graphite::params {

  $autoupgrade = false
  $carbon_config_file            = "${module_name}/etc/carbon/carbon.conf.erb"
  $ensure = 'present'
  $firewall                      = false
  $status = 'enabled'
  $time_zone                     = "America/New_York" # see http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  $web_apache_config_file        = "${module_name}/etc/httpd/conf.d/graphite-web.conf.erb"
  $web_dashboard_config_file     = "${module_name}/etc/graphite-web/dashboard.conf.erb"
  $web_local_settings_file       = "${module_name}/etc/graphite-web/local_settings.py.erb"
  $web_server_name               = "${::fqdn}"
  $web_server_port               = 8080
  $web_use_hostname_server_alias = true

  case $::operatingsystem {
    'CentOS', 'Fedora', 'RedHat', 'Amazon' ,'Scientific': {
      $package_carbon  = [ 'python-carbon' ]
      $package_whisper = [ 'python-whisper' ]
      $package_web     = [ 'graphite-web']
      $service_default_path     = '/etc/sysconfig'
      $service_cache_name       = 'carbon-cache'
      $service_cache_hasrestart = true
      $service_cache_hasstatus  = true
      $service_cache_pattern    = $service_cache_name
      $service_relay_name       = 'carbon-relay'
      $service_relay_hasrestart = true
      $service_relay_hasstatus  = true
      $service_relay_pattern    = $service_relay_name
      $service_aggregator_name       = 'carbon-aggregator'
      $service_aggregator_hasrestart = true
      $service_aggregator_hasstatus  = true
      $service_aggregator_pattern    = $service_aggregator_name
    }
    default: {
      fail("'${module_name}' does not support operating system '${::operatingsystem}'")
    }
  }

}
