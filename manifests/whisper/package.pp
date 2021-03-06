class graphite::whisper::package {

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

  package { $graphite::params::package_whisper:
    ensure => $package_ensure,
  }

}
