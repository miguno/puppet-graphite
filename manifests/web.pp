# == Class: graphite::web
#
# This class is able to install or remove graphite web on a node.
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
# [*admin_password*]
#   String.  The hash of the password of the graphite-web admin user.  You must
#   use the PBKDF2 algorithm with a SHA256 hash to properly hash the password.
#
#   You can use Python to create your own custom password  as follows (you must
#   have a recent version of Django installed locally).  The following example
#   hashes (encrypts) the password 'wirbelsturm' with a salt of 'yhmSGMwIMU0t'.
#
#   >>> from django.utils.crypto import pbkdf2
#   >>> import base64, hashlib
#   >>> algorithm = 'pbkdf2_sha256'
#   >>> iterations = 10000
#   >>> salt = 'yhmSGMwIMU0t'
#   >>> plaintext_password = 'wirbelsturm'
#   >>> hash = pbkdf2(plaintext_password, salt, iterations, 32, hashlib.sha256).encode('base64').strip()
#   >>> hashed_password = '{algorithm}${iterations}${salt}${hash}'.format(algorithm=algorithm,iterations=iterations,salt=salt,hash=hash)
#   >>> print hashed_password
#   pbkdf2_sha256$10000$yhmSGMwIMU0t$HDegvfcy2i14qhQgWhDP7fL5Pf658Cfu065iv0e8YlE=
#
#   Q.v.:
#   * {Password management in Django}[https://docs.djangoproject.com/en/dev/topics/auth/passwords/]
#   Defaults to the hash of the password <tt>wirbelsturm</tt>.
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
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
class graphite::web(
  $admin_email             = 'admin@example.com',
  $admin_password          = 'pbkdf2_sha256$10000$yhmSGMwIMU0t$HDegvfcy2i14qhQgWhDP7fL5Pf658Cfu065iv0e8YlE=',
  $admin_user              = 'admin',
  $autoupgrade             = hiera('graphite::autoupgrade', $graphite::params::autoupgrade),
  $dashboard_config_template       = "${module_name}/etc/graphite-web/dashboard.conf.erb",
  $django_secret_key       = 'UNSAFE_DEFAULT',
  $ensure                  = $graphite::params::ensure,
  $db                      = '/var/lib/graphite-web/graphite.db',
  $db_init_file            = '/tmp/graphite_initial_data.json.json',
  $db_init_file_template   = "${module_name}/initial_data.json.erb",
  $gunicorn_autorestart    = hiera('graphite::web::gunicorn_autorestart', true),
  $gunicorn_config         = '/etc/graphite-web/gunicorn.conf.py',
  $gunicorn_config_template        = "${module_name}/etc/graphite-web/gunicorn.conf.py.erb",
  $gunicorn_command        = 'gunicorn_django -c /etc/graphite-web/gunicorn.conf.py',
  $gunicorn_enable         = hiera('graphite::web::gunicorn_enable', true),
  $gunicorn_ensure         = 'present',
  $gunicorn_manage         = hiera('graphite::web::gunicorn_manage', true),
  $gunicorn_name           = 'gunicorn',
  $gunicorn_port           = 8081,
  $gunicorn_retries        = 999,
  $gunicorn_startsecs      = 10,
  $gunicorn_stderr_logfile_keep    = 10,
  $gunicorn_stderr_logfile_maxsize = '20MB',
  $gunicorn_stdout_logfile_keep    = 5,
  $gunicorn_stdout_logfile_maxsize = '20MB',
  $gunicorn_stopasgroup    = hiera('graphite::web::gunicorn_stopasgroup', false),
  $gunicorn_stopsignal     = 'TERM',
  $gunicorn_timeout        = 30,
  $gunicorn_workers        = 2,
  $limits_manage           = hiera('graphite::web::limits_manage', false),
  $limits_nofile           = 65536,
  $local_settings_template = "${module_name}/etc/graphite-web/local_settings.py.erb",
  $log_dir                 = '/var/log/graphite-web',
  $status                  = $graphite::params::status,
  $storage_dir             = '/var/lib/graphite-web',
  $use_hostname_server_alias = hiera('graphite::web::use_hostname_server_alias', true),
  $version                 = undef,
  $webserver_group         = $graphite::params::webserver_group,
  $webserver_module        = $graphite::params::webserver_module,
  $webserver_port          = 8080,
  $webserver_user          = $graphite::params::webserver_user,
) inherits graphite::params {

  validate_string($admin_email)
  validate_string($admin_password)
  validate_string($admin_user)
  validate_bool($autoupgrade)
  validate_string($dashboard_config_template)
  validate_string($django_secret_key)
  if ! ($ensure in [ 'present', 'absent' ]) { fail("\"${ensure}\" is not a valid ensure parameter value") }
  validate_absolute_path($db)
  validate_absolute_path($db_init_file)
  validate_string($db_init_file_template)
  validate_bool($gunicorn_autorestart)
  validate_string($gunicorn_command)
  validate_absolute_path($gunicorn_config)
  validate_string($gunicorn_config_template)
  validate_bool($gunicorn_enable)
  validate_string($gunicorn_ensure)
  validate_bool($gunicorn_manage)
  validate_string($gunicorn_name)
  if !is_integer($gunicorn_port) { fail('The $gunicorn_port parameter must be an integer number') }
  if !is_integer($gunicorn_retries) { fail('The $gunicorn_retries parameter must be an integer number') }
  if !is_integer($gunicorn_startsecs) { fail('The $gunicorn_startsecs parameter must be an integer number') }
  if !is_integer($gunicorn_stderr_logfile_keep) {                                                                            fail('The $gunicorn_stderr_logfile_keep parameter must be an integer number')
  }
  validate_string($gunicorn_stderr_logfile_maxsize)
  if !is_integer($gunicorn_stdout_logfile_keep) {                                                                            fail('The $gunicorn_stdout_logfile_keep parameter must be an integer number')
  }
  validate_string($gunicorn_stdout_logfile_maxsize)
  validate_bool($gunicorn_stopasgroup)
  validate_string($gunicorn_stopsignal)
  if !is_integer($gunicorn_timeout) { fail('The $gunicorn_timeout parameter must be an integer number') }
  if !is_integer($gunicorn_workers) { fail('The $gunicorn_workers parameter must be an integer number') }
  validate_bool($limits_manage)
  if !is_integer($limits_nofile) { fail('The $limits_nofile parameter must be an integer number') }
  validate_string($local_settings_template)
  validate_absolute_path($log_dir)
  if ! ($status in [ 'enabled', 'disabled', 'running', 'unmanaged' ]) {
    fail("\"${status}\" is not a valid status parameter value")
  }
  validate_absolute_path($storage_dir)
  validate_bool($use_hostname_server_alias)
  validate_string($version)
  validate_string($webserver_group)
  if !is_integer($webserver_port) { fail('The $webserver_port parameter must be an integer number') }
  validate_string($webserver_user)

  class { 'graphite::web::install': }
  class { 'graphite::web::config': }
  class { 'graphite::web::gunicorn': }

  if $ensure == 'present' {
    Class['graphite::web::install'] -> Class['graphite::web::config'] ~> Class['graphite::web::gunicorn']
  }
  else {
    # TODO: Implement removal of graphite-web
  }

}
