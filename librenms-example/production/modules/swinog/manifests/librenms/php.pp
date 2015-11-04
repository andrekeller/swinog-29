class swinog::librenms::php {

  ## Supervisor to run PHP FPM master processes
  class { 'supervisord':
    package_ensure   => 'present',
    service_ensure   => 'running',
    package_provider => 'apt',
    service_name     => 'supervisor',
    executable       => '/usr/bin/supervisord',
    executable_ctl   => '/usr/bin/supervisorctl',
    install_init     => false,
    config_include   => '/etc/supervisor/conf.d',
    config_file      => '/etc/supervisor/supervisor.conf',
  }

  $php_extensions = {
    'gd'         => {
      'provider' => 'apt',
    },
    'snmp'     => {
      'provider' => 'apt',
    },
    'curl'     => {
      'provider' => 'apt',
    },
    'mcrypt'     => {
      'provider' => 'apt',
    },
    'json'     => {
      'provider' => 'apt',
    },
  }
  class {'::php':
    ensure       => 'present',
    pear         => false,
    manage_repos => false,
    extensions   => $php_extensions,
  } ->
  package {['php-pear', 'php-net-ipv4', 'php-net-ipv6']:
    ensure => 'present',
  }->
  class {'::mysql::bindings':
    php_enable => true,
  }

  # Overwrite the php5-fpm service definition
  Service <| tag == 'php5-fpm' |> {
    ensure => stopped,
  }

  $fpm_command = '/usr/sbin/php5-fpm --nodaemonize --fpm-config'
  ::swinog::librenms::php::fpmpool {'librenms':
    php_admin_values => {
      'date.timezone' => 'Europe/Zurich',
    },
    require          => Class['::php'],
  } ~>
  ::supervisord::supervisorctl {'restart_librenms-fpmpool':
    command     => 'restart',
    process     => 'librenms-fpmpool',
    refreshonly => true,
  }
  ::supervisord::program {'librenms-fpmpool':
    ensure                  => 'present',
    ensure_process          => 'running',
    user                    => 'root',
    autorestart             => true,
    autostart               => true,
    redirect_stderr         => true,
    stdout_logfile_backups  => '7',
    stdout_logfile_maxbytes => '10MB',
    stopsignal              => 'QUIT',
    command                 => "${fpm_command} /etc/php5/fpm/librenms.conf",
    require                 => [
      File['/etc/php5/fpm/librenms.conf'],
      User['www-data'],
    ]
  }

}
