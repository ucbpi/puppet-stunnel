# == Class: stunnel
#
# STunnel Management
#
class stunnel (
  $tunnels = {},
) {
  file { '/usr/local/bin/stunnel-combine-certs':
    ensure => 'present',
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/stunnel/stunnel-combine-certs.rb',
  }

  include stunnel::install, stunnel::config
  Class['Stunnel::Install'] -> Class['Stunnel::Config']

  if $tunnels {
    validate_hash($tunnels)
    ensure_resources('stunnel::tun', $tunnels)
  }
}
