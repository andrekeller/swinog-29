class swinog::ssl::snakeoil {

  package {'ssl-cert':
    ensure => 'present',
  }->
  file {'/etc/ssl/certs/ssl-cert-snakeoil.pem':
    ensure => 'file',
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0444',
  }->
  file {'/etc/ssl/private/ssl-cert-snakeoil.key':
    ensure => 'file',
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0440',
  }

}
