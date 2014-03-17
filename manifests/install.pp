# == Class: stunnel::install
#
# Installs the required packages for stunnel and this module
#
class stunnel::install {
  ensure_packages( [ 'stunnel' ] )

  if $::osfamily == 'RedHat' {
    ensure_packages( [ 'redhat-lsb' ] )
  }
}
