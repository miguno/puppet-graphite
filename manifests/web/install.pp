class graphite::web::install {

  if $graphite::ensure == 'present' {
    if $graphite::version == undef {
      $package_ensure = $graphite::autoupgrade ? {
        true  => 'latest',
        false => 'present',
      }
    }
    else {
      $package_ensure = $graphite::version
    }
  }
  else {
    $package_ensure = 'purged'
  }

  package { $graphite::params::package_web:
    ensure => $package_ensure,
  }

  package { $graphite::params::package_gunicorn:
    ensure => $package_ensure,
  }

  if $graphite::ensure == 'present' {

    file { 'graphite-db-dir':
      path    => '/var/lib/graphite-web',
      ensure  => directory,
      owner   => "${graphite::web::webserver_user}",
      group   => "${graphite::web::webserver_group}",
      mode    => '0755',
      require => Package[$graphite::params::package_web],
    }

    file { 'graphite-log-dir':
      path    => '/var/log/graphite-web',
      ensure  => directory,
      owner   => "${graphite::web::webserver_user}",
      group   => "${graphite::web::webserver_group}",
      mode    => '0755',
      require => Package[$graphite::params::package_web],
    }

    file { $graphite::web::db_init_file:
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => template($graphite::web::db_init_file_template),
    }

    # The initial data was created from a fresh install via:
    # $ python manage.py syncdb
    #    <...enter example data...>
    # $ python manage.py dumpdata --indent=2 auth > initial_data.json
    exec { 'initialize-database':
      command => "python ${graphite::web::managepy_path} syncdb --noinput && python ${graphite::web::managepy_path} loaddata ${graphite::web::db_init_file}",
      path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
      unless  => "test -f ${graphite::web::db}",
      require => [ File['graphite-db-dir'], File['graphite-log-dir'], File[$graphite::web::db_init_file] ],
    }
    ->
    file { $graphite::web::db:
      ensure  => file,
      owner   => "$graphite::web::webserver_user",
      group   => "$graphite::web::webserver_group",
    }

    if $graphite::web::limits_manage == true {
      limits::fragment {
        "${graphite::params::graphite_web_user}/soft/nofile": value => $graphite::web::limits_nofile;
        "${graphite::params::graphite_web_user}/hard/nofile": value => $graphite::web::limits_nofile;
      }
    }

  }
  else {
    # TODO: Revert our changes to /etc/security/limits.conf, if any
  }

}
