# puppet-graphite

[Wirbelsturm](https://github.com/miguno/wirbelsturm)-compatible [Puppet](http://puppetlabs.com/) module to deploy
[Graphite](http://graphite.wikidot.com/).

_Note: This module is a work in progress.  The code still needs some cleaning and better style._

---

Table of Contents

* <a href="#installation">Installation</a>
* <a href="#usage">Usage and configuration</a>
    * <a href="#general">General configuration</a>
    * <a href="#carbon">Configuring carbon</a>
    * <a href="#graphite-web">Configuring graphite-web</a>
    * <a href="#whisper">Configuring whisper</a>
* <a href="#requirements">Requirements</a>
* <a href="#assumptions">Assumptions</a>
* <a href="#faq">FAQ</a>
* <a href="#credits">Credits</a>

---

<a name="installation"></a>

# Installation

It is recommended to use [librarian-puppet](https://github.com/rodjek/librarian-puppet) to add this module to your
Puppet setup.

Add the following lines to your `Puppetfile`:

```
# Add the dependencies as hosted on public Puppet Forge.
#
# We intentionally do not include e.g. the stdlib dependency in our Modulefile to make it easier for users who decided
# to use internal copies of stdlib so that their deployments are not coupled to the availability of PuppetForge.  While
# there are tools such as puppet-library for hosting internal forges or for proxying to the public forge, not everyone
# is actually using those tools.
mod 'puppetlabs/stdlib'
mod 'ispavailability/file_concat', '0.1.0'

# Add the puppet-graphite module
mod 'graphite',
  :git => 'https://github.com/miguno/puppet-graphite.git'
```

Then use librarian-puppet to install (or update) the Puppet modules.


<a name="usage"></a>

# Usage and configuration


<a name="general"></a>

## General configuration

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


<a name="carbon"></a>

## Configuring carbon

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


### Configuring max number of open files (limits.conf)

You can optionally configure the maximum number of open files for the user running carbon daemons.  Doing so will create
an entry in `/etc/security/limits.conf` (note: this is an implementation detail and should not be relied upon) for the
user running the carbon daemons.  By default, such an entry will not be created.

Example configuration:

```yaml
# Optional: Manage /etc/security/limits.conf to tune the maximum number
# of open files, which is a typical setting you may need to change for
# production environments.  Default: false (do not manage)
graphite::carbon::limits_manage: true
graphite::carbon::limits_nofile: 32768
```


<a name="graphite-web"></a>

## Configuring graphite-web

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


### Configuring max number of open files (limits.conf)

You can optionally configure the maximum number of open files for the user running graphite-web.  Doing so will create
an entry in `/etc/security/limits.conf` (note: this is an implementation detail and should not be relied upon) for the
user running graphite-web.  By default, such an entry will not be created.

Example configuration:

```yaml
# Optional: Manage /etc/security/limits.conf to tune the maximum number
# of open files, which is a typical setting you may need to change for
# production environments.  Default: false (do not manage)
graphite::web::limits_manage: true
graphite::web::limits_nofile: 32768
```


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



<a name="whisper"></a>

## Configuring whisper

Whisper is the storage for all the data.
This one has no special configuration.


<a name="requirements"></a>

# Requirements

* Tested with RHEL/CentOS 6
* Puppet 3.x
* Ruby 1.9 (preferred) or 1.8


<a name="assumptions"></a>

# Assumptions

Certain assumptions have been made with this module:

1. Carbon, graphite-web & whisper are available through a package repository.
2. When no config files are specified, the default ones are used.
3. All three applications are standard installed.
4. For the three processes from carbon; unless activated they are not running.
5. If you want to run graphite-web, then supervisord 3.x must be available through a package repository and you have
   loaded the [puppet-supervisor](https://github.com/miguno/puppet-supervisor) module (e.g. through librarian-puppet)
   as forked by miguno.
6. If you want to configure the maximum number of open files (`nofile` in `/etc/security/limits.conf`) through this
   Puppet module, then you must have loaded the [puppet-limits](https://github.com/miguno/puppet-limits) module (e.g.
   through librarian-puppet) as forked by miguno.


<a name="faq"></a>

# FAQ

## Configure additional users and groups for Graphite web UI?

Once graphite-web is up and running you can access its user management component (driven by Django) at:

    http://<graphite-root-url>/admin/

You must login with a user account that has superuser rights or the relevant permissions  in order to be able to add,
modify and remove users and groups (the initial `admin` user has such permissions).


## Manually create a graphite-web admin / superuser account?

Graphite-web is based on Django, so you can follow the standard Django procedures.

    $ sudo python /path/to/manage.py createsuperuser

It is recommended to use the name `admin` for the admin/superuser account.


## Reset admin password for graphite-web?

Graphite-web is based on Django, so you can follow the standard Django procedures.

    $ sudo python /path/to/manage.py changepassword admin


Alternatively you can also use the Django shell:

    $ sudo python /path/to/manage.py shell
    Python 2.6.6 (r266:84292, Oct 12 2012, 14:23:48)
    >>> from django.contrib.auth.models import User
    >>> user = User.objects.get(username='normaluser')
    >>> user.set_password('plain password')  # Don't enter the salted/hashed version here!
    >>> user.save()

Other helpful `User` methods are:

    >>> admins = User.objects.filter(is_superuser=True)

See [How to reset django admin password](http://stackoverflow.com/questions/6358030/how-to-reset-django-admin-password)
for more information.


## Get a dump of the Graphite web UI database?

_Note: This is about the database Graphite uses to store user accounts and dashboards.  It is NOT about the actual_
_metrics, which are stored in Whisper files._

    $ sudo python /path/to/manage.py dumpdata > /tmp/django-dump.json

See [Bootstrap the Django DB](http://obfuscurity.com/2012/04/Unhelpful-Graphite-Tip-4) for more information.


<a name="credits"></a>

# Credits

This module is based on -- and a fork of -- the great work done by
[electrical](https://github.com/electrical/puppet-graphite).
