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

      if versioncmp($::operatingsystemmajrelease, '7') >= 0 {
        $service_init_system = 'systemd'
      } else {
        $service_init_system = 'sysv'
      }
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

      if ($::operatingsystem == 'Ubuntu' and versioncmp($::operatingsystemrelease, '15.04') >= 0) or
         ($::operatingsystem == 'Debian' and versioncmp($::operatingsystemrelease, '8.0') >= 0) {
        $service_init_system = 'systemd'
      } else {
        $service_init_system = 'sysv'
      }
    }

    default: {
      fail("Unsupported osfamily '${::osfamily}'!")
    }
  }
}
