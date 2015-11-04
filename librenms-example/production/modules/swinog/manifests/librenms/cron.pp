define swinog::librenms::cron (
  $command,
  $ensure = 'present',
  $minute = undef,
  $hour = undef,
  $command_args = undef,
  $command_runner = undef,
){

  if ($command_runner) {
    $_command = "test -f ${command} && ${command_runner} ${command}"
  }
  else {
    $_command = "test -x ${command} && ${command}"
  }
  if ($command_args) {
    $_command_args = $command_args
  }
  else {
    $_command_args = ''
  }
  cron {"librenms-${title}":
    ensure  => $ensure,
    user    => 'librenms',
    minute  => $minute,
    hour    => $hour,
    command => "${_command} ${_command_args} >> /dev/null 2>&1",
  }

}
