class graphite::carbon::relay::service inherits graphite::carbon::relay::params {

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
        firewall { '101 Graphite: allow access to carbon-relay line receiver port':
          port    => $graphite::carbon::relay_line_receiver_port,
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
    file { 'carbon_relay_init_file':
      ensure => present,
      path   => '/etc/init.d/carbon-relay',
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => $init_file,
      before => Service['carbon-relay'],
    }
  }

  if ($default_file != undef) {
    file { 'carbon_relay_default_file':
      ensure => present,
      path   => "${graphite::params::service_default_path}/carbon-relay",
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => $default_file,
      before => Service['carbon-relay'],
    }
  }

  service { 'carbon-relay':
    ensure     => $service_ensure,
    enable     => $service_enable,
    name       => $graphite::params::service_relay_name,
    hasstatus  => $graphite::params::service_relay_hasstatus,
    hasrestart => $graphite::params::service_relay_hasrestart,
    pattern    => $graphite::params::service_relay_pattern,
  }

}
