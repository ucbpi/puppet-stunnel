# == stunnel::data
#
#
class stunnel::config {
  include stunnel::data

  $stunnel_dirs = [
    $stunnel::data::config_dir,
    $stunnel::data::conf_d_dir,
  ]

  file { $stunnel_dirs:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
  }

  file { $stunnel::data::log_dir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
