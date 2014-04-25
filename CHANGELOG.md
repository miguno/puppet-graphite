# Change log

## 0.0.5 (April 25, 2014)

* Better handling of storage directories for carbon and graphite-web:  We support now the two parameters
  `$graphite::carbon::storage_dir` and `$graphite::web::storage_dir`, respectively.
* Location of log directory of graphite-web is now configurable via `$graphite::web::log_dir`.


## 0.0.4 (April 08, 2014)

IMPROVEMENTS

* Remove `puppetlabs/stdlib` from `Modulefile` to decouple us from PuppetForge.


## 0.0.3 (February 28, 2014)

BACKWARDS INCOMPATIBILITY

* Drop firewall support.


## 0.0.2 (November 06, 2013)

BACKWARDS INCOMPATIBILITY

* Drop Debian and Ubuntu support because it was never really tested anyways upstream.

IMPROVEMENTS

* Significant refactoring, including but not limited to:
    * Adding/improving support for e.g. carbon-aggregator and carbon-relay
    * Clean-up of the original 0.0.1 code
    * Support more Graphite/Carbon configuration parameters
    * Add support for RHEL operating system family including Amazon Linux
    * Improved input validation of Puppet parameters
* Extend and improve user documentation, e.g. how to create custom Django passwords


## 0.0.1 (January 19, 2013)

* Initial release of the module (upstream repo, i.e. before our fork)
