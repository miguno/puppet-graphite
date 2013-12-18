class graphite::web::gunicorn {

  if !($graphite::web::gunicorn_ensure in ['present', 'absent']) {
    fail("gunicorn_ensure parameter must be 'present' or 'absent'")
  }

  if $graphite::ensure == 'present' and $graphite::web::gunicorn_manage == true {

    supervisor::service {
      $graphite::web::gunicorn_name:
        ensure                 => $graphite::web::gunicorn_ensure,
        enable                 => $graphite::web::gunicorn_enable,
        command                => $graphite::web::gunicorn_command,
        directory              => $graphite::web::gunicorn_directory,
        user                   => $graphite::web::webserver_user,
        group                  => $graphite::web::webserver_group,
        autorestart            => $graphite::web::gunicorn_autorestart,
        startsecs              => $graphite::web::gunicorn_startsecs,
        retries                => $graphite::web::gunicorn_retries,
        stopsignal             => $graphite::web::gunicorn_stopsignal,
        stopasgroup            => $graphite::web::gunicorn_stopasgroup,
        stdout_logfile_maxsize => $graphite::web::gunicorn_stdout_logfile_maxsize,
        stdout_logfile_keep    => $graphite::web::gunicorn_stdout_logfile_keep,
        stderr_logfile_maxsize => $graphite::web::gunicorn_stderr_logfile_maxsize,
        stderr_logfile_keep    => $graphite::web::gunicorn_stderr_logfile_keep,
        require                => [
                                    File[$graphite::web::gunicorn_config],
                                    Package[$graphite::params::package_gunicorn],
                                    Class['::supervisor'],
                                  ],
    }

    if $graphite::web::gunicorn_enable == true {
      exec { 'restart-gunicorn':
        command     => "supervisorctl restart ${graphite::web::gunicorn_name}",
        path        => ["/usr/bin", "/usr/sbin", "/sbin", "/bin"],
        user        => 'root',
        refreshonly => true,
        subscribe   => File[$graphite::web::gunicorn_config],
        onlyif      => "which supervisorctl &>/dev/null",
        require     => Class['::supervisor'],
      }
    }

    # TODO: Configure firewall for gunicorn if needed
  }

}
