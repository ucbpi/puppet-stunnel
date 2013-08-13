# == Define: stunnel::tun
#
# Setup a secure tunnel
#
# === Parameters
#
# [*services*]
#
# [*cert*]
#   Certificate to use for this tunnel
#
# [*options*]
#   Options to pass to openssl.  To disable SSLv2 on your tunnel, you could pass
#   "NO_SSLv2" as an option.
#
# [*template*]
#   The ERB template to use when generating the configuration
#
# [*timeoutidle*]
#   The idle timeout for the connection. Defaults to 60 seconds.
#
# [*debug*]
#   Set the debug level for stunnel.  Valid values are any valid syslog
#   [facility.]level
#
define stunnel::tun (
  $services,
  $cert = 'UNSET',
  $options = '',
  $setgid = 'UNSET',
  $setuid = 'UNSET',
  $template = 'stunnel/tun.erb',
  $timeoutidle = '60',
  $debug = '0',
) {
  include stunnel
  include stunnel::data

  $cert_real = $cert ? {
    'UNSET' => "${stunnel::data::cert_dir}/${name}.pem",
    default => $cert,
  }
  validate_absolute_path( $cert_real )

  $pid = "${stunnel::data::pid_dir}/${name}.pid"
  $output = "${stunnel::data::log_dir}/${name}.log"
  $setuid_real = $setuid ? {
    'UNSET' => $stunnel::data::setuid,
    default => $setuid,
  }

  $setgid_real = $setgid ? {
    'UNSET' => $stunnel::data::setgid,
    default => $setgid,
  }

  file { "${stunnel::data::conf_d_dir}/${name}.conf":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('stunnel/tun.erb'),
  }

  # make sure we process our stunnel class first
  Class['stunnel'] -> Class['stunnel::data'] -> Stunnel::Tun[$title]
}
