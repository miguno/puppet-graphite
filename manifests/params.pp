# == Class: graphite::params
#
# This class exists to
# 1. Declutter the default value assignment for class parameters.
# 2. Manage internally used module variables in a central place.
#
# Therefore, many operating system dependent differences (names, paths, ...)
# are addressed in here.
#
#
# === Parameters
#
# This class does not provide any parameters.
#
#
# === Examples
#
# This class is not intended to be used directly.
#
#
# === Links
#
# * {Puppet Docs: Using Parameterized Classes}[http://j.mp/nVpyWY]
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
class graphite::params {

  #### Default values for the parameters of the main module class, init.pp

  # ensure
  $ensure = 'present'

  # autoupgrade
  $autoupgrade = false

  # service status
  $status = 'enabled'

  #### Internal module values

  $carbon_config_file            = "${module_name}/etc/carbon/carbon.conf.erb"
  $firewall                      = false
  $time_zone                     = "America/New_York" # see http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  $web_apache_config_file        = "${module_name}/etc/httpd/conf.d/graphite-web.conf.erb"
  $web_dashboard_config_file     = "${module_name}/etc/graphite-web/dashboard.conf.erb"
  $web_local_settings_file       = "${module_name}/etc/graphite-web/local_settings.py.erb"
  $web_server_name               = "${::fqdn}"
  $web_server_port               = 80
  $web_use_hostname_server_alias = true

  # packages
  case $::operatingsystem {
    'CentOS', 'Fedora', 'Scientific': {
      # main application
      $package_carbon  = [ 'python-carbon' ]
      $package_whisper = [ 'python-whisper' ]
      $package_web     = [ 'graphite-web']
    }
    'Debian', 'Ubuntu': {
      # main application
      $package_carbon  = [ 'graphite-carbon' ]
      $package_whisper = [ 'python-whisper' ]
      $package_web     = [ 'graphite-web' ] # available since Debian Jessie
    }
    default: {
      fail("\"${module_name}\" provides no package default value
            for \"${::operatingsystem}\"")
    }
  }

  # service parameters
  case $::operatingsystem {
    'CentOS', 'Fedora', 'Scientific': {
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
    'Debian', 'Ubuntu': {
      $service_default_path     = '/etc/default'

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
      fail("\"${module_name}\" provides no service parameters
            for \"${::operatingsystem}\"")
    }
  }

}
