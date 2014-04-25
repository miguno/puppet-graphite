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
      ensure  => directory,
      path    => $graphite::web::storage_dir,
      owner   => $graphite::web::webserver_user,
      group   => $graphite::web::webserver_group,
      mode    => '0755',
      require => [
        Package[$graphite::params::package_web],
        Class[$graphite::web::webserver_module],
      ],
    }

    file { 'graphite-log-dir':
      ensure  => directory,
      path    => '/var/log/graphite-web',
      owner   => $graphite::web::webserver_user,
      group   => $graphite::web::webserver_group,
      mode    => '0755',
      require => [
        Package[$graphite::params::package_web],
        Class[$graphite::web::webserver_module],
      ],
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
      owner   => $graphite::web::webserver_user,
      group   => $graphite::web::webserver_group,
      require => Class[$graphite::web::webserver_module],
    }

    if $graphite::web::limits_manage == true {
      limits::fragment { "${graphite::web::webserver_user}/soft/nofile":
        value => $graphite::web::limits_nofile,
        require => Class[$graphite::web::webserver_module],
      }
      limits::fragment { "${graphite::web::webserver_user}/hard/nofile":
        value => $graphite::web::limits_nofile,
        require => Class[$graphite::web::webserver_module],
      }
    }

  }
  else {
    # TODO: Revert our changes to /etc/security/limits.conf, if any
  }

}
