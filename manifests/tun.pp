# == Define: stunnel::tun
#
# Setup a secure tunnel
#
# === Parameters
#
# [*accept*]
#   accept connections on the specified address.
#
# [*cafile*]
#   cafile to use for this tunnel
#
# [*cert*]
#   Certificate to use for this tunnel
#
# [*client*]
#   Whether this tunnel should be setup in client mode.
#
# [*options*]
#   Options to pass to openssl.  To disable SSLv2 on your tunnel, you could
#   pass "NO_SSLv2" as an option. This parameter should be passed an array, but
#   for backwards compatability a single option can be passed as a string.
#
# [*template*]
#   The ERB template to use when generating the configuration
#
# [*timeoutidle*]
#   The idle timeout for the connection. Defaults to 43200.
#
# [*debug*]
#   Set the debug level for stunnel.  Valid values are any valid syslog
#   [facility.]level
#
# [*failover*]
#   Configure the failover strategy for the service when using multiple backend
#   servers. Valid values are 'rr' and 'prio', 'rr' being round robin and 'prio'
#   being priority/failover (stunnel attempts to connect to backend servers in
#   specified order).
#
# [*output*]
#   location of logfile for this tunnel. if left unspecified, defaults to
#   /var/log/stunnel/${name}.log, where ${name} is the name of the tunnel
#   resource.
#
# [*global_opts*]
#   hash of key/value pairs for additional stunnel global configuration options
#   that are not already exposed as parameters.
#
# [*service_opts*]
#   hash of key/value pairs for additional stunnel service configuration options
#   that are not already exposed as parameters.
#
define stunnel::tun (
  $accept,
  $connect,
  $cafile = '',
  $cert = 'UNSET',
  $client = false,
  $options = [ ],
  $failover = 'rr',
  $template = 'stunnel/tun.erb',
  $timeoutidle = '43200',
  $debug = '5',
  $install_service = true,
  $service_ensure = 'running',
  $output = 'UNSET',
  $global_opts = { },
  $service_opts = { },
) {
  require stunnel
  include stunnel::data

  validate_hash( $global_opts )
  validate_hash( $service_opts )
  validate_re( $failover, '(rr|prio)', '$failover must be either \'rr\' or \'prio\'')

  $cafile_real = $cafile ? {
    'UNSET' => '',
    default => $cafile,
  }

  # Clients don't require a certificate but servers do
  if $client {
    $cert_default = ''
  } else {
    $cert_default = "${stunnel::data::cert_dir}/${name}.pem"
  }
  if $cert == 'UNSET' {
    $cert_real = $cert_default
  } else {
    $cert_real = $cert
  }

  if $cafile_real != '' {
    validate_absolute_path( $cafile_real )
  }
  if $cert_real != '' {
    validate_absolute_path( $cert_real )
  }
  validate_bool( str2bool($client) )

  if is_string($options) {
    $options_r = [ $options ]
  } elsif is_array($options) {
    $options_r = $options
  } else {
    fail('$options must be an array, or a string containing a single option')
  }

  $pid = "${stunnel::data::pid_dir}/stunnel-${name}.pid"
  $output_r = $output ? {
    'UNSET' => "${::stunnel::data::log_dir}/${name}.log",
    default => $output,
  }
  validate_absolute_path($output_r)

  $prog = $stunnel::data::bin_name
  $svc_bin = "${stunnel::data::bin_path}/${stunnel::data::bin_name}"

  $config_file = "${stunnel::data::conf_d_dir}/${name}.conf"
  file { $config_file:
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template("${template}"),
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
      ensure    => $service_ensure,
      enable    => true,
      require   => File["/etc/init.d/stunnel-${name}"],
      subscribe => File[$config_file],
    }
  }
}
