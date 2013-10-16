class graphite::carbon::package {

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
  else {
    $package_ensure = 'purged'
  }

  package { $graphite::params::package_carbon:
    ensure   => $package_ensure,
  }

}
