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
  $accept,
  $connect,
  $cert = 'UNSET',
  $options = '',
  $template = 'stunnel/tun.erb',
  $timeoutidle = '60',
  $debug = '0',
  $install_service = true,
) {
  require stunnel
  include stunnel::data

  $cert_real = $cert ? {
    'UNSET' => "${stunnel::data::cert_dir}/${name}.pem",
    default => $cert,
  }
  validate_absolute_path( $cert_real )

  $pid = "${stunnel::data::pid_dir}/stunnel-${name}.pid"
  $output = "${stunnel::data::log_dir}/${name}.log"
  $prog = $stunnel::data::bin_name
  $svc_bin = "${stunnel::data::bin_path}/${stunnel::data::bin_name}"

  $config_file = "${stunnel::data::conf_d_dir}/${name}.conf"
  file { $config_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('stunnel/tun.erb'),
  }

  # setup our init script / service
  $initscript_ensure = $install_service ? {
    true    => 'present',
    default => 'absent',
  }
  file { "/etc/init.d/stunnel-${name}":
    ensure  => $initscript_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0550',
    content => template('stunnel/stunnel.init.erb'),
  }
  if $install_service {
    service { "stunnel-${name}":
      enable    => true,
      require   => File["/etc/init.d/stunnel-${name}"],
      subscribe => $config
    }
  }
}
