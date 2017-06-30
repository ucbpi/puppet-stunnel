# == stunnel::data
#
#
class stunnel::config {
  include stunnel::data

  $stunnel_config_dirs = [
    $stunnel::data::config_dir,
    $stunnel::data::conf_d_dir
  ]

  file {
    $stunnel::data::log_dir:
      ensure => directory,
      owner  => $stunnel::data::setuid,
      group  => $stunnel::data::setgid,
      mode   => '0755';

    $stunnel_config_dirs:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0555';
  }
}
