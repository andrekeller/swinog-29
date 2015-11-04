class swinog::librenms (
  $hostname,
  $database_root_password,
  $database_librenms_password,
  $port = 443,
  $ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key',
){

  ::identity::user {'librenms':
    ensure      => 'present',
    comment     => 'LibreNMS',
    manage_home => false,
    system      => true,
    home        => '/opt/librenms',
  }
  vcsrepo { '/opt/librenms':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/librenms/librenms.git',
    revision => 'master',
    owner    => 'librenms',
    group    => 'librenms',
    require  => ::Identity::User['librenms'],
  }
  file {[
    '/opt/librenms',
    '/opt/librenms/log',
    '/opt/librenms/rrd',
  ]:
    ensure  => 'directory',
    owner   => 'librenms',
    group   => 'librenms',
    mode    => '0770',
    require => ::Identity::User['librenms'],
  }

  package {[
    'fping',
    'git',
    'graphviz',
    'imagemagick',
    'mtr',
    'nmap',
    'python-mysqldb',
    'rrdtool',
    'snmp',
    'snmpd',
    'whois',
  ]:
    ensure => 'present',
  }

  $cron_threads = $::processorcount * 4
  $crons = {
    'discovery-all' => {
      'minute'       => '33',
      'hour'         => '*/6',
      'command'      => '/opt/librenms/discovery.php',
      'command_args' => '-h all',
    },
    'discovery-new' => {
      'minute'       => '*/5',
      'command'      => '/opt/librenms/discovery.php',
      'command_args' => '-h new',
    },
    'poller'        => {
      'minute'       => '*/5',
      'command'      => '/opt/librenms/poller-wrapper.py',
      'command_args' => $cron_threads,
    },
    'update'        => {
      'minute'         => '15',
      'hour'           => '0',
      'command_runner' => 'sh',
      'command'        => '/opt/librenms/poller-wrapper.py',
      'command_args'   => $cron_threads,
    },
    'alerts'        => {
      'command' => '/opt/librenms/alerts.php',
    },
    'pool-billing' => {
      'minute'     => '*/5',
      'command'    => '/opt/librenms/poll-billing.php',
    },
    'billing-calculate' => {
      'minute'     => '01',
      'command'    => '/opt/librenms/billing-calculate.php',
    },
    'autoupdate' => {
      'minute'  => '45',
      'hour'    => '4',
      'command' => '/opt/librenms/daily.sh',
    },
  }
  create_resources('::swinog::librenms::cron', $crons)

  class {'::mysql::server':
    root_password           => $database_root_password,
    remove_default_accounts => true,
  }->
  ::mysql::db {'librenms':
    user     => 'librenms',
    password => $database_librenms_password,
  }

  class {'::swinog::librenms::php':
  }

  $dhparam = '/etc/ssl/private/nginx-dhparam.pem'
  swinog::ssl::dhparam {$dhparam:
  }
  ::identity::user {'www-data':
    comment     => 'Nginx User',
    groups      => ['librenms'],
    home        => '/var/www',
    manage_home => false,
    shell       => '/usr/sbin/nologin',
    system      => true,
    uid         => 33,
    require     => Group['librenms'],
  }->
  class {'::nginx::config':
    client_max_body_size => '200m',
    http_cfg_append      => {
      'large_client_header_buffers' => '4 32k',
      'proxy_busy_buffers_size'     => '64k',
    },
    proxy_buffers        => '8 32k',
    proxy_buffer_size    => '32k',
    proxy_read_timeout   => '1200',
    server_tokens        => 'off',
    types_hash_max_size  => '2048',
    vhost_purge          => true,
  }
  class {'::nginx':
    manage_repo  => false,
  }
  nginx::resource::vhost{$hostname:
    index_files    => ['index.php'],
    listen_ip      => '[::]',
    listen_options => 'ipv6only=off',
    listen_port    => $port,
    ssl            => true,
    ssl_cert       => $ssl_cert,
    ssl_key        => $ssl_key,
    ssl_ciphers    => 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:ECDHE-RSA-DES-CBC3-SHA:ECDHE-ECDSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:AES:CAMELLIA:DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5:!PSK:!aECDH:!EDH-DSS-DES-CBC3-SHA:!EDH-RSA-DES-CBC3-SHA:!KRB5-DES-CBC3-SHA',
    ssl_protocols  => 'TLSv1 TLSv1.1 TLSv1.2',
    ssl_dhparam    => $dhparam,
    ssl_port       => $port,
    try_files      => ['$uri', '$uri/', '@librenms'],
    www_root       => '/opt/librenms/html',
    require        => [
      File[$ssl_cert],
      File[$ssl_key],
      File[$dhparam],
    ],
  }
  File[$ssl_cert] ~> Service['nginx']
  File[$ssl_key] ~> Service['nginx']
  File[$dhparam] ~> Service['nginx']
  nginx::resource::location{'librenms-php':
    location           => '~ \.php',
    fastcgi            => 'unix:/var/run/php5-fpm-librenms.sock',
    fastcgi_split_path => '^(.+\.php)(/.*)$',
    index_files        => [],
    www_root           => '/opt/librenms/html',
    vhost              => $hostname,
    ssl_only           => true,
  }
  nginx::resource::location{'librenms-ht':
    location      => '~ /\.ht',
    location_deny => ['all'],
    index_files   => [],
    vhost         => $hostname,
    www_root      => '/opt/librenms/html',
    ssl_only      => true,
  }
  nginx::resource::location{'librenms-librenms':
    location      => '@librenms',
    rewrite_rules => [
      '^api/v0(.*)$ /api_v0.php/$1 last',
      '^(.+)$ /index.php/$1 last',
    ],
    index_files   => [],
    vhost         => $hostname,
    www_root      => '/opt/librenms/html',
    ssl_only      => true,
  }

}
