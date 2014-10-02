# Class: stunnel::data
#
# Poorly named 'params' class, this class handles all the os-specific logic.
#
class stunnel::data {
  case $::osfamily {
    /RedHat/: {
      $package = [ 'stunnel', 'redhat-lsb' ]
      $service = 'stunnel'
      $bin_name = 'stunnel'
      $bin_path = '/usr/bin'
      $config_dir = '/etc/stunnel'
      $pid_dir = '/var/run'
      $conf_d_dir = '/etc/stunnel/conf.d'
      $cert_dir = '/etc/stunnel/certs'
      $log_dir = '/var/log/stunnel'
      $setgid = 'root'
      $setuid = 'root'
    }
    /Debian/: {
      $package = [ 'stunnel4', 'lsb-base' ]
      $service = 'stunnel'
      $bin_name = 'stunnel4'
      $bin_path = '/usr/bin'
      $config_dir = '/etc/stunnel'
      $pid_dir = '/var/run'
      $conf_d_dir = '/etc/stunnel/conf.d'
      $cert_dir = '/etc/stunnel/certs'
      $log_dir = '/var/log/stunnel4'
      $setgid = 'root'
      $setuid = 'root'
    }

    default: {
      fail("Unsupported osfamily '${::osfamily}'!")
    }
  }
}
