# puppet-graphite

A Puppet module for managing and configuring [Graphite](http://graphite.wikidot.com/).


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

```shell
(django-sandbox) $ python
>>> from django.utils.crypto import pbkdf2
>>> import base64, hashlib
>>> algorithm = 'pbkdf2_sha256'
>>> iterations = 10000
>>> salt = 'yhmSGMwIMU0t'
>>> plaintext_password = 'wirbelsturm'
>>> hash = pbkdf2(plaintext_password, salt, iterations, 32, hashlib.sha256).encode('base64').strip()
>>> hashed_password = '{algorithm}${iterations}${salt}${hash}'.format(algorithm=algorithm,iterations=iterations,salt=salt,hash=hash)
>>> print hashed_password
pbkdf2_sha256$10000$yhmSGMwIMU0t$HDegvfcy2i14qhQgWhDP7fL5Pf658Cfu065iv0e8YlE=
```

You would then use `pbkdf2_sha256$10000$yhmSGMwIMU0t$HDegvfcy2i14qhQgWhDP7fL5Pf658Cfu065iv0e8YlE=` as the value for
`graphite::web::admin_password`.

See [Password management in Django](https://docs.djangoproject.com/en/dev/topics/auth/passwords/).


## whisper

Whisper is the storage for all the data.
This one has no special configuration.


# Assumptions

Certain assumptions have been made with this module:

1. Carbon, graphite-web & whisper are available through a package repository.
2. When no config files are specified, the default ones are used.
3. All three applications are standard installed.
4. For the three processes from carbon; unless activated they are not running.
