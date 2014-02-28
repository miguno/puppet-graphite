class graphite::web::config {

  file { '/etc/graphite-web':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644'
  }

  file { '/etc/graphite-web/local_settings.py':
    ensure  => present,
    content => template($graphite::web::local_settings_template),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon']
  }

  file { '/etc/graphite-web/dashboard.conf':
    ensure  => present,
    content => template($graphite::web::dashboard_config_template),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon']
  }

  file { $graphite::web::gunicorn_config:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template($graphite::web::gunicorn_config_template),
  }

}
