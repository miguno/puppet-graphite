class graphite::carbon::config {

  ### General configuration

  file { '/etc/carbon':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { 'carbon-main-config':
    path    => '/etc/carbon/carbon.conf',
    ensure  => present,
    content => template("$graphite::carbon::carbon_config_template"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon'],
  }

  ### carbon-aggregator

  file { 'aggregator-config':
    path    => '/etc/carbon/aggregation-rules.conf',
    ensure  => file,
    content => template("$graphite::carbon::aggregator_config_template"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon'],
  }

  ### carbon-cache

  file_fragment { "header_${::fqdn}":
    tag     => "carbon_cache_storage_config_${::fqdn}",
    content => template("${module_name}/etc/carbon/storage-schemas-header.erb"),
    order   => 01,
  }

  file_concat { 'carbon-storage-schemas':
    path    => '/etc/carbon/storage-schemas.conf',
    tag     => "carbon_cache_storage_config_${::fqdn}",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon'],
  }

  file { 'storage-aggregation':
    path    => '/etc/carbon/storage-aggregation.conf',
    ensure  => file,
    content => template("$graphite::carbon::storage_aggregation_config_template"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon'],
  }

  file { $graphite::carbon::storage_dir:
    ensure       => directory,
    owner        => $graphite::params::graphite_carbon_user,
    group        => $graphite::params::graphite_carbon_group,
    mode         => '0755',
    recurse      => true,
    recurselimit => 0,
  }

}
