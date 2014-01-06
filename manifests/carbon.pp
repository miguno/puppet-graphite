# TODO: Update the documentation of this class to match the actual code.
#
# == Class: graphite::carbon
#
# This class is able to install or remove graphite carbon cache on a node.
# It manages the status of the related service.
#
#
# === Parameters
#
# [*ensure*]
#   String. Controls if the managed resources shall be <tt>present</tt> or
#   <tt>absent</tt>. If set to <tt>absent</tt>:
#   * The managed software packages are being uninstalled.
#   * Any traces of the packages will be purged as good as possible. This may
#     include existing configuration files. The exact behavior is provider
#     dependent. Q.v.:
#     * Puppet type reference: {package, "purgeable"}[http://j.mp/xbxmNP]
#     * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   * System modifications (if any) will be reverted as good as possible
#     (e.g. removal of created users, services, changed log settings, ...).
#   * This is thus destructive and should be used with care.
#   Defaults to <tt>present</tt>.
#
# [*autoupgrade*]
#   Boolean. If set to <tt>true</tt>, any managed package gets upgraded
#   on each Puppet run when the package provider is able to find a newer
#   version than the present one. The exact behavior is provider dependent.
#   Q.v.:
#   * Puppet type reference: {package, "upgradeable"}[http://j.mp/xbxmNP]
#   * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   Defaults to <tt>false</tt>.
#
# [*status*]
#   String to define the status of the service. Possible values:
#   * <tt>enabled</tt>: Service is running and will be started at boot time.
#   * <tt>disabled</tt>: Service is stopped and will not be started at boot
#     time.
#   * <tt>running</tt>: Service is running but will not be started at boot time.
#     You can use this to start a service on the first Puppet run instead of
#     the system startup.
#   * <tt>unmanaged</tt>: Service will not be started at boot time and Puppet
#     does not care whether the service is running or not. For example, this may
#     be useful if a cluster management software is used to decide when to start
#     the service plus assuring it is running on the desired node.
#   Defaults to <tt>enabled</tt>. The singular form ("service") is used for the
#   sake of convenience. Of course, the defined status affects all services if
#   more than one is managed (see <tt>service.pp</tt> to check if this is the
#   case).
#
# [*version*]
#   String to set the specific version you want to install.
#   Defaults to <tt>undef</tt>.
#
# The default values for the parameters are set in graphite::params. Have
# a look at the corresponding <tt>params.pp</tt> manifest file if you need more
# technical information about them.
class graphite::carbon(
  $aggregator_config_template    = "${module_name}/etc/carbon/aggregation-rules.conf.erb",
  $aggregator_enable = hiera('graphite::carbon::aggregator_enable', false),
  $aggregator_line_receiver_port = 2023,
  $aggregator_rules  = [],
  $autoupgrade       = hiera('graphite::autoupgrade', $graphite::params::autoupgrade),
  $cache_enable      = hiera('graphite::carbon::cache_enable', false),
  $cache_line_receiver_port      = 2003,
  $cache_max_creates_per_minute  =   50,
  $cache_max_updates_per_second  =  500,
  $cache_query_port  = 7002,
  $carbon_config_template        = "${module_name}/etc/carbon/carbon.conf.erb",
  $ensure            = $graphite::params::ensure,
  $limits_manage     = hiera('graphite::carbon::limits_manage', false),
  $limits_nofile     = 65536,
  $relay_enable      = hiera('graphite::carbon::relay_enable', false),
  $relay_line_receiver_port      = 2013,
  $status            = $graphite::params::status,
  $storage_aggregation_config_template = "${module_name}/etc/carbon/storage-aggregation.conf.erb",
  $storage_dir       = $graphite::params::storage_dir,
  $version           = undef,
) inherits graphite::params {

  validate_string($aggregator_config_template)
  validate_bool($aggregator_enable)
  if !is_integer($aggregator_line_receiver_port) {
    fail('The $aggregator_line_receiver_port parameter must be an integer number')
  }
  validate_array($aggregator_rules)
  validate_bool($autoupgrade)
  validate_bool($cache_enable)
  if !is_integer($cache_line_receiver_port) {
    fail('The $cache_line_receiver_port parameter must be an integer number')
  }
  if !is_integer($cache_max_creates_per_minute) {
    fail('The $cache_max_creates_per_minute parameter must be an integer number')
  }
  if !is_integer($cache_max_updates_per_second) {
    fail('The $cache_max_updates_per_second parameter must be an integer number')
  }
  if !is_integer($cache_query_port) { fail('The $cache_query_port parameter must be an integer number') }
  validate_string($carbon_config_template)
  if ! ($ensure in [ 'present', 'absent' ]) {
    fail("\"${ensure}\" is not a valid ensure parameter value")
  }
  validate_bool($limits_manage)
  if !is_integer($limits_nofile) { fail('The $limits_nofile parameter must be an integer number') }
  validate_bool($relay_enable)
  if !is_integer($relay_line_receiver_port) { fail('The $relay_line_receiver_port parameter must be an integer number') }
  if ! ($status in [ 'enabled', 'disabled', 'running', 'unmanaged' ]) {
    fail("\"${status}\" is not a valid status parameter value")
  }
  validate_string($storage_aggregation_config_template)
  validate_absolute_path($storage_dir)
  validate_string($version)


  class { 'graphite::carbon::package': }
  class { 'graphite::carbon::config': }

  $storage_rules = hiera('graphite::carbon::cache::storage_rules', {})
  create_resources('graphite::carbon::cache::storage', $storage_rules)

  if $cache_enable == true {
    class { 'graphite::carbon::cache::service': }
  }

  if $relay_enable == true {
    class { 'graphite::carbon::relay::service': }
  }

  if $aggregator_enable == true {
    class { 'graphite::carbon::aggregator::service': }
  }

  if $ensure == 'present' {

    if $cache_enable == true {
      Class['graphite::carbon::package'] -> Class['graphite::carbon::cache::service']
      Class['graphite::carbon::config']  ~> Class['graphite::carbon::cache::service']
    }

    if $relay_enable == true {
      Class['graphite::carbon::package'] -> Class['graphite::carbon::relay::service']
      Class['graphite::carbon::config']  ~> Class['graphite::carbon::relay::service']
    }

    if $aggregator_enable == true {
      Class['graphite::carbon::package'] -> Class['graphite::carbon::aggregator::service']
      Class['graphite::carbon::config']  ~> Class['graphite::carbon::aggregator::service']
    }

    # We need the software before configuring it.
    Class['graphite::carbon::package'] -> Class['graphite::carbon::config']
  }
  else {
    # Make sure all services are getting stopped before software removal.
    if $cache_enable == true {
      Class['graphite::carbon::cache::service'] -> Class['graphite::carbon::package']
    }

    if $relay_enable == true {
      Class['graphite::carbon::relay::service'] -> Class['graphite::carbon::package']
    }

    if $aggregator_enable == true {
      Class['graphite::carbon::aggregator::service'] -> Class['graphite::carbon::package']
    }
  }

}
