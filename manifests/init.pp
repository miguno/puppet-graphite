# == Class: graphite
#
# This class is able to install or remove graphite on a node.
# It manages the status of the related service.
#
# [Add description - What does this module do on a node?] FIXME/TODO
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
# [*time_zone*]
#   String to configure the time zone used by Graphite.
#   Q.v.:
#   * Allowed values: {List of tz database time zones}[http://en.wikipedia.org/wiki/List_of_tz_database_time_zones]
#   Defaults to <tt>America/New_York</tt>.
#
# [*version*]
#   String to set the specific version you want to install.
#   Defaults to <tt>undef</tt>.
#
# The default values for the parameters are set in graphite::params. Have
# a look at the corresponding <tt>params.pp</tt> manifest file if you need more
# technical information about them.
#
#
# === Examples
#
# * Installation, make sure service is running and will be started at boot time:
#     class { 'graphite': }
#
# * Removal/decommissioning:
#     class { 'graphite':
#       ensure => 'absent',
#     }
#
# * Install everything but disable service(s) afterwards
#     class { 'graphite':
#       status => 'disabled',
#     }
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
class graphite(
  $autoupgrade                    = $graphite::params::autoupgrade,
  $carbon_cache_enable            = false,
  $carbon_relay_enable            = false,
  $carbon_aggregator_enable       = false,
  $carbon_config_file             = $graphite::params::carbon_config_file,
  $carbon_cache_init_file         = undef,
  $carbon_cache_default_file      = undef,
  $carbon_relay_init_file         = undef,
  $carbon_relay_default_file      = undef,
  $carbon_aggregator_init_file    = undef,
  $carbon_aggregator_default_file = undef,
  $ensure                         = $graphite::params::ensure,
  $firewall                       = $graphite::params::firewall,
  $status                         = $graphite::params::status,
  $time_zone                      = $graphite::params::time_zone,
  $web_apache_config_file         = $graphite::params::web_apache_config_file,
  $web_dashboard_config_file      = $graphite::params::web_dashboard_config_file,
  $web_local_settings_file        = $graphite::params::web_local_settings_file,
  $web_server_name                = $graphite::params::web_server_name,
  $web_server_port                = $graphite::params::web_server_port,
  $web_use_hostname_server_alias  = $graphite::params::web_use_hostname_server_alias,
  $version                        = undef,
) inherits graphite::params {

  #### Validate parameters

  validate_bool($autoupgrade)
  if ! ($ensure in [ 'present', 'absent' ]) {
    fail("\"${ensure}\" is not a valid ensure parameter value")
  }
  validate_bool($carbon_cache_enable)
  validate_bool($carbon_relay_enable)
  validate_bool($carbon_aggregator_enable)
  validate_string($carbon_config_file)
  validate_bool($firewall)
  if ! ($status in [ 'enabled', 'disabled', 'running', 'unmanaged' ]) {
    fail("\"${status}\" is not a valid status parameter value")
  }
  validate_string($web_apache_config_file)
  validate_string($web_dashboard_config_file)
  validate_string($web_local_settings_file)
  validate_string($web_server_name)
  if !is_integer($web_server_port) {
    fail('The $web_server_port parameter must be an integer number')
  }
  validate_bool($web_use_hostname_server_alias)

  #### Manage actions

  class { 'graphite::carbon':
    cache_enable      => $carbon_cache_enable,
    relay_enable      => $carbon_relay_enable,
    aggregator_enable => $carbon_aggregator_enable,
    config_file       => $carbon_config_file,
  }

  class { 'graphite::whisper': }

  class { 'graphite::web':
    dashboard_config_file => $web_dashboard_config_file,
    local_settings_file   => $web_local_settings_file,
  }

}
