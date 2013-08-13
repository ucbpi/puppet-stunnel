# == stunnel::data
#
#
class stunnel::config {
  include stunnel::data

  file { [ $stunnel::data::config_dir, $stunnel::data::conf_d_dir ]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
  }
}
