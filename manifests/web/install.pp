class graphite::web::install {

  if $graphite::ensure == 'present' {
    if $graphite::version != undef {
      $package_ensure = $graphite::autoupgrade ? {
        true  => 'latest',
        false => 'present',
      }
    }
    else {
      $package_ensure = $graphite::version
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
    exec { 'create-database':
      command => "python ${managepy_path} syncdb --noinput && python ${managepy_path} loaddata ${graphite::web::db_init_file}",
      path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
      unless  => "test -f ${graphite::web::db}",
      require => [ Package[$graphite::params::package_web], File[$graphite::web::db_init_file] ],
    }
    ->
    file { $graphite::web::db:
      ensure  => file,
      owner   => "$graphite::web::webserver_user",
      group   => "$graphite::web::webserver_group",
    }
  }
  else {
    $package_ensure = 'purged'
  }

  package { $graphite::params::package_web:
    ensure => $package_ensure,
  }

}
