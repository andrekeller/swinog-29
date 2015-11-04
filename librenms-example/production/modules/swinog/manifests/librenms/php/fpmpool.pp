define swinog::librenms::php::fpmpool (
  $ensure = 'present',
  $fpm_listen_backlog = '-1',
  $fpm_max_children = 50,
  $fpm_max_requests = 0,
  $fpm_start_servers = 5,
  $fpm_min_spare_servers = 5,
  $fpm_max_spare_servers = 35,
  $php_admin_values = undef,
  $php_admin_flags = undef,
  $php_values = undef,
){

  file {"/etc/php5/fpm/${title}.conf":
    ensure  => $ensure,
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0644',
    content => template('swinog/librenms/phpfpm_pool.conf.erb'),
  }

}
