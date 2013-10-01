class graphite::web::config {

  file { '/etc/graphite-web':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  }

  file { '/etc/graphite-web/local_settings.py':
    ensure  => present,
    content => template($graphite::web::local_settings_file),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon']
  }

  file { '/etc/graphite-web/dashboard.conf':
    ensure  => present,
    content => template($graphite::web::dashboard_config_file),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon']
  }

  if ($graphite::status in ['enabled', 'running', 'unmanaged']) {
    if $graphite::firewall == true {
      firewall { '100 Graphite: allow access to Graphite web port':
        port    => $graphite::server_port,
        proto   => 'tcp',
        action  => 'accept',
        require => Class['::firewall'],
      }
    }
  }

}
