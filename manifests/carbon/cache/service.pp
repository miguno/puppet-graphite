class graphite::carbon::cache::service inherits graphite::carbon::cache::params {

  if $graphite::ensure == 'present' {

    case $graphite::status {
      # Make sure service is currently running, start it on boot.
      'enabled': {
        $service_ensure = 'running'
        $service_enable = true
      }
      # Make sure service is currently stopped, do not start it on boot.
      'disabled': {
        $service_ensure = 'stopped'
        $service_enable = false
      }
      # Make sure service is currently running, do not start it on boot.
      'running': {
        $service_ensure = 'running'
        $service_enable = false
      }
      # Do not start service on boot, do not care whether currently running or not.
      'unmanaged': {
        $service_ensure = undef
        $service_enable = false
      }
      # Unknown status
      # Note: Don't forget to update the parameter check in init.pp if you
      #       add a new or change an existing status.
      default: {
        fail("\"${graphite::status}\" is an unknown service status value")
      }
    }

    if ($graphite::status in ['enabled', 'running', 'unmanaged']) {
      if $graphite::firewall == true {
        firewall { '101 Graphite: allow access to carbon-cache line receiver port':
          port    => $graphite::carbon::cache_line_receiver_port,
          proto   => 'tcp',
          action  => 'accept',
          require => Class['::firewall'],
        }
        firewall { '102 Graphite: allow access to carbon-cache cache query port':
          port    => $graphite::carbon::cache_query_port,
          proto   => 'tcp',
          action  => 'accept',
          require => Class['::firewall'],
        }
      }
    }
  }
  else {
    # Make sure the service is stopped and disabled (the removal itself will be
    # done by package.pp).
    $service_ensure = 'stopped'
    $service_enable = false
  }

  if ($init_file != undef) {
    file { 'carbon_cache_init_file':
      ensure => present,
      path   => '/etc/init.d/carbon-cache',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => $init_file,
      before => Service['carbon-cache'],
    }
  }

  if ($default_file != undef) {
    file { 'carbon_cache_default_file':
      ensure => present,
      path   => "${graphite::params::service_default_path}/carbon-cache",
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => $default_file,
      before => Service['carbon-cache'],
    }
  }

  service { 'carbon-cache':
    ensure     => $service_ensure,
    enable     => $service_enable,
    name       => $graphite::params::service_cache_name,
    hasstatus  => $graphite::params::service_cache_hasstatus,
    hasrestart => $graphite::params::service_cache_hasrestart,
    pattern    => $graphite::params::service_cache_pattern,
  }

}
