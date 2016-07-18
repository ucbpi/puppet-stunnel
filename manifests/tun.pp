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
# [*ensure*]
#   whether to set up or remove this tunnel. Valid values are 'absent' and
#   'present'. Defaults to 'present'.
#
# [*install_service*]
#   Whether or not to install an init script for this tunnel (boolean).
#   Defaults to true
#
# [*service_init_system*]
#   Which init system will be managing this service. Valid values are 'sysv'
#   and 'systemd'.
#   Defaults to 'sysv'
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
  $service_init_system = 'UNSET',
  $output = 'UNSET',
  $global_opts = { },
  $service_opts = { },
  $ensure = 'present',
) {
  require stunnel
  include stunnel::data

  validate_hash( $global_opts )
  validate_hash( $service_opts )
  validate_re( $failover, '^(rr|prio)$', '$failover must be either \'rr\' or \'prio\'')
  validate_re( $ensure, '^(absent|present)$', '$ensure must be either \'absent\' or \'present\'')

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

  $service_init_system_real = $service_init_system ? {
    'UNSET' => $::stunnel::data::service_init_system,
    default => $service_init_system,
  }
  validate_re( $service_init_system_real, '^(sysv|systemd)$',
    '$service_init_system must be either \'sysv\' or \'systemd\'')

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
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template($template),
  }

  # setup our init script / service
  if $install_service and $ensure == 'present' {
    $initscript_ensure = 'present'
  } else {
    $initscript_ensure = 'absent'
  }
  if $service_init_system_real == 'sysv' {
    $initscript_file = "/etc/init.d/stunnel-${name}"
    file { $initscript_file:
      ensure  => $initscript_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0550',
      content => template('stunnel/stunnel.init.erb'),
    }
  } elsif $service_init_system_real == 'systemd' {
    $initscript_file = "/etc/systemd/system/stunnel-${name}.service"
    file { $initscript_file:
      ensure  => $initscript_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('stunnel/stunnel.init.systemd.erb'),
    }
  }
  if $install_service or $ensure == 'absent' {
    if $ensure == 'absent' {
      $service_ensure_real = 'stopped'
      $service_enable = false
      # When removing, the init file should be removed after the service is
      # stopped
      $service_require = undef
      $service_before = File[$initscript_file]
    } else {
      $service_ensure_real = $service_ensure
      $service_enable = true
      # When installing, the init file should be created before the service is
      # started
      $service_require = File[$initscript_file]
      $service_before = undef
    }
    service { "stunnel-${name}":
      ensure    => $service_ensure_real,
      enable    => $service_enable,
      require   => $service_require,
      before    => $service_before,
      subscribe => File[$config_file],
    }
  }
}
