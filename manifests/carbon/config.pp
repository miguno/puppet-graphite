class graphite::carbon::config {

  ### General configuration

  file { '/etc/carbon':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file { '/etc/carbon/carbon.conf':
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

  file_concat { '/etc/carbon/storage-schemas.conf':
    tag     => "carbon_cache_storage_config_${::fqdn}",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File['/etc/carbon'],
  }

}
