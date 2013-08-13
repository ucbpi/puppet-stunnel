# stunnel Module #

# Usage #

This module initially intended for use with xinetd.  While these examples make
use of arusso-xinetd, it is not a requirement, hence the lack of the explicit
dependency in the ModuleFile.

## Examples ##

Setup an stunnel for 0.0.0.0:993 to localhost:994.  Because stunnel wants a cert
file with the private key, and intermediate and signed cert in a single file, we
have the stunnel::cert type to combine the certs together for you.  Certs are
combined in the order they appear in the array.  Certs are stored in
/etc/stunnel/certs/ by default, and have permissions 600 and owned by root.

    include stunnel
    $imaps_service = {
      'accept'  => '0.0.0.0:993',
      'connect' => '127.0.0.1:994',
    }
    stunnel::tun { 'imaps':
      services => { 'imaps' => $imaps_service },
      options  => 'NO_SSLv2',
    }

    stunnel::cert { 'imaps':
      components => [ '/etc/pki/tls/certs/public-cert.crt', '/etc/pki/tls/private/private.key' ],
    }

    include xinetd
    xinetd_imaps = {
      'disable'        => 'no',
      'type'           => 'unlisted',
      'port'           => '993',
      'socket_type'    => 'stream',
      'wait'           => 'no',
      'user'           => 'root',
      'protocol'       => 'tcp',
      'server'         => '/usr/bin/stunnel',
      'server_args'    => '/etc/stunnel/conf.d/imaps.conf',
    }
    xinetd::service_entry { 'stunnel-imaps':
      ensure  => 'present',
      options => $xinetd_imaps,
    }

License
-------

See LICENSE file

Copyright
---------

Copyright &copy; 2013 The Regents of the University of California


Contact
-------

Aaron Russo <arusso@berkeley.edu>

Support
-------

Please log tickets and issues at the
[Projects site](https://github.com/arusso/puppet-stunnel/issues/)
