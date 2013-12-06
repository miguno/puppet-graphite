class graphite::carbon::package {

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

  package { $graphite::params::package_carbon:
    ensure   => $package_ensure,
  }

  if $graphite::ensure == 'present' {

    if $graphite::carbon::limits_manage == true {
      limits::fragment {
        "${graphite::params::graphite_carbon_user}/soft/nofile": value => $graphite::carbon::limits_nofile;
        "${graphite::params::graphite_carbon_user}/hard/nofile": value => $graphite::carbon::limits_nofile;
      }
    }

  }
  else {
    # TODO: Revert our changes to /etc/security/limits.conf, if any
  }

}
