define graphite::carbon::cache::storage(
  $pattern,
  $retentions,
  $order = 10
) {

  file_fragment { "${$name}_${::fqdn}":
    tag     => "carbon_cache_storage_config_${::fqdn}",
    content => template("${module_name}/etc/carbon/storage-schemas-item.erb"),
    order   => $order
  }

}
