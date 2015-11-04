define swinog::ssl::dhparam (
  $size = '2048'
){

  exec {"generate dhparam ${title}":
    command => "/usr/bin/openssl dhparam -out ${title} ${size}",
    creates => $title,
    require => Package['ssl-cert'],
  
  }->
  file {$title:
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0440',
  }

}
