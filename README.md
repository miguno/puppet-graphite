# puppet-graphite

A Wirbelsturm-compatible Puppet module for managing and configuring [Graphite](http://graphite.wikidot.com/).

_Note: This module is a work in progress.  The code still needs some cleaning and better style._


# Compatibility

* Puppet 3.x
* Tested with RHEL/CentOS 6


# Usage

Installation, make sure service is running and will be started at boot time:

     class { 'graphite': }

Removal/decommissioning:

     class { 'graphite':
       ensure => 'absent',
     }

Install everything but disable service(s) afterwards:

     class { 'graphite':
       status => 'disabled',
     }


## carbon

Carbon is 1 of the applications for graphite.
You can activate the 3 separate services individually depending on requirments.

Common config variables:

     # Template
     carbon_config_file => "${module_name}/etc/carbon/carbon.conf.erb"


### cache

     carbon_cache_enable => true

Once carbon-cache is running you can send metrics to it via e.g. port `2003/tcp` (default for the line
receiver port of carbon-cache).

Command line example:

    # Format is "<metric> <value> <timestamp>"
    $ echo "local.random.diceroll 4 `date +%s`" | nc localhost 2003

See [Feeding Carbon](https://graphite.readthedocs.org/en/latest/feeding-carbon.html) for more information.


### relay

     carbon_relay_enable => true


### aggregator

     carbon_aggregator_enable => true


### storage definitions

For defining the storage methods a define is in place:

     graphite::carbon::cache::storage { 'default_1min_for_1day':
       pattern    => '.*'
       retentions => '60s:1d'
     }

An other of sequence can be given with the order => directive.


## web

For the graphite-web there are 2 variables:

    # Templates
    web_dashboard_config_file => "${module_name}/etc/graphite-web/dashboard.conf.erb"
    web_local_settings_file   => "${module_name}/etc/graphite-web/local_settings.py.erb"

The default superuser of the graphite-web application is user `admin` with password `wirbelsturm` and email address
`admin@example.com`.


### Create your own hashed password for the admin user of graphite-web

You can define a custom superuser for graphite-web via the parameters:

    $graphite::web::admin_user
    $graphite::web::admin_password
    $graphite::web::admin_email

The password must be in an encrypted, hashed format.  You can use Python to create your own custom password as follows
(you must have a recent version of Django installed locally).  The following example hashes (encrypts) the password
`wirbelsturm` with a salt of `yhmSGMwIMU0t`.

First we will install Django in a local sandbox because we only need it to create hashed passwords:

    $ sudo pip install virtualenv
    $ virtualenv /tmp/django-sandbox
    $ cd /tmp/django-sandbox
    $ source bin/activate
    (django-sandbox) $ pip install django

Now you can use Python to encrypt your password:

    (django-sandbox) $ python
    >>> from django.utils.crypto import pbkdf2
    >>> import base64, hashlib
    >>> algorithm = 'pbkdf2_sha256'
    >>> iterations = 10000
    >>> salt = 'yhmSGMwIMU0t'               # <<<< Pick your own random string instead of this one.
    >>> plaintext_password = 'wirbelsturm'  # <<<< Use your own unencrypted password here.
    >>> hash = pbkdf2(plaintext_password, salt, iterations, 32, hashlib.sha256).encode('base64').strip()
    >>> hashed_password = '{algorithm}${iterations}${salt}${hash}'.format(algorithm=algorithm,iterations=iterations,salt=salt,hash=hash)
    >>> print hashed_password
    pbkdf2_sha256$10000$yhmSGMwIMU0t$HDegvfcy2i14qhQgWhDP7fL5Pf658Cfu065iv0e8YlE=

You would then use `pbkdf2_sha256$10000$yhmSGMwIMU0t$HDegvfcy2i14qhQgWhDP7fL5Pf658Cfu065iv0e8YlE=` as the value for
`graphite::web::admin_password`.

Lastly we destroy our local Django sandbox as we do not need it anymore:

    >>> exit()
    (django-sandbox) $ deactivate
    $ rm -rf /tmp/django-sandbox

See [Password management in Django](https://docs.djangoproject.com/en/dev/topics/auth/passwords/).


### Example configuration with Nginx (using Hiera)

This example was tested on RHEL 6.  It runs gunicorn on port `8081/tcp` for serving graphite-web, and nginx on port
`8080/tcp` is acting as the main frontend that relays requests to gunicorn.  Note that the various `www_root` parameters
are specific to the RedHat OS family.

This example requires the Puppet module [puppet-nginx](https://github.com/jfryman/puppet-nginx) for managing nginx.

```yaml
---
classes:
  - graphite
  - nginx

## Graphite
#
# Note: If clients connecting to carbon-cache are experiencing errors such as connection refused by the daemon, a common
# reason is a shortage of file descriptors (ulimit -n).  A value of 8192 or more may be necessary depending on how many
# clients are simultaneously connecting to the carbon-cache daemon.
graphite::carbon_cache_enable: true
graphite::web::admin_email: 'your.email@example.com'
graphite::web::django_secret_key: 'kja0x0w3qdjf;kjtg098yh#%&ISZFGH'

## Nginx
nginx::nginx_upstreams:
  'gunicorn_app_server':
    ensure: 'present'
    members:
      - 'localhost:8081 fail_timeout=0'
nginx::nginx_vhosts:
  '_':
    www_root: '/usr/share/graphite/webapp/content'
    ipv6_enable: false
    listen_port: 8080
    access_log: '/var/log/nginx/monitor1.access.log'
    error_log:  '/var/log/nginx/monitor1.error.log'
    vhost_cfg_append:
      client_max_body_size: '64M'
      keepalive_timeout: 5
    location_cfg_append:
      proxy_pass_header: 'Server'
      proxy_redirect: 'off'
      'proxy_set_header X-Real-IP': '$remote_addr'
      'proxy_set_header Host': '$http_host'
      'proxy_set_header X-Scheme': '$scheme'
      proxy_connect_timeout: 10
      proxy_read_timeout: 10
      proxy_pass: 'http://gunicorn_app_server'
nginx::nginx_locations:
  'media':
    vhost: '_'
    location: '/media/'
    www_root: '/usr/lib/python2.6/site-packages/django/contrib/admin'
```



## whisper

Whisper is the storage for all the data.
This one has no special configuration.


# Assumptions

Certain assumptions have been made with this module:

1. Carbon, graphite-web & whisper are available through a package repository.
2. When no config files are specified, the default ones are used.
3. All three applications are standard installed.
4. For the three processes from carbon; unless activated they are not running.
5. If you want to run graphite-web, then supervisord 3.x must be available through a package repository and you have
   loaded the [puppet-supervisor](https://github.com/miguno/puppet-supervisor) module (e.g. through librarian-puppet)
   as forked by miguno.
