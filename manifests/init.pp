# == Class: stunnel
#
# STunnel Management
#
class stunnel {
  include stunnel::install, stunnel::config
  Class['Stunnel::Install'] -> Class['Stunnel::Config']
}
