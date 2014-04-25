class graphite::params {

  $autoupgrade      = false
  $ensure           = 'present'
  $webserver_module = '::nginx' # Puppet module, here: puppet-nginx
  $status           = 'enabled'
  $time_zone        = "UTC" # see http://en.wikipedia.org/wiki/List_of_tz_database_time_zones
  $version          = undef

  case $::operatingsystem {
    'CentOS', 'Fedora', 'RedHat', 'Amazon' ,'Scientific': {
      $graphite_carbon_group    = 'carbon' # Controlled by the RPM
      $graphite_carbon_user     = 'carbon' # Controlled by the RPM
      # TODO: Try to auto-detect location if possible
      $graphite_pythonpath      = '/usr/lib/python2.6/site-packages/graphite'
      $managepy_path    = "${graphite_pythonpath}/manage.py"
      $package_carbon   = [ 'python-carbon' ]
      $package_gunicorn = [ 'python-gunicorn' ]
      $package_whisper  = [ 'python-whisper' ]
      $package_web      = [ 'graphite-web' ]
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
      $webserver_group  = 'nginx'
      $webserver_user   = 'nginx'
    }
    default: {
      fail("'${module_name}' does not support operating system '${::operatingsystem}'")
    }
  }

}
