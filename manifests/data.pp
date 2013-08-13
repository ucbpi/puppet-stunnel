class stunnel::data {
  case $::osfamily {
    /RedHat/: {
      $package = 'stunnel'
      $service = 'stunnel'
      $config_dir = '/etc/stunnel'
      $pid_dir = '/var/run'
      $conf_d_dir = '/etc/stunnel/conf.d'
      $cert_dir = '/etc/stunnel/certs'
      $log_dir = '/var/log/stunnel'
      $setgid = 'root'
      $setuid = 'root'
    }

    default: {
      fail("Unsupported osfamily '${::osfamily}'!")
    }
  }
}
