class graphite::web::package {

  #### Package management

  # set params: in operation
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
  }
  # set params: removal
  else {
    $package_ensure = 'purged'
  }

  # action
  package { $graphite::params::package_web:
    ensure => $package_ensure,
  }

}
