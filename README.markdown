# stunnel Module #

[![Build Status](https://travis-ci.org/arusso/puppet-stunnel.png?branch=master)](https://travis-ci.org/arusso/puppet-stunnel)

This is an stunnel module that provides support for multiple tunnels, each with
their own initscript.

## Examples ##

Setup a tunnel, accepting connections on `:993` and sending them to
`localhost:143`, using a pre-built cert at `/etc/certs/stunnel-imaps.pem`:

    include stunnel
    stunnel::tun { 'imaps':
      accept  => '993',
      connect => 'localhost:143',
      options => 'NO_SSLv2',
      cert    => '/etc/certs/stunnel-imaps.pem',
    }
  
stunnel is picky about the certs.  You can find more information about it 
[here](https://www.stunnel.org/static/stunnel.html) in the `CERTIFICATES`
section.

If you don't want to mess with rebuilding your cert each time the certs you base
it off of get updated, you can use the `stunnel::cert` class to your benefit:

    stunnel::cert { 'imaps':
      components => [ '/etc/pki/tls/private/private.key',
                      '/etc/pki/tls/certs/public.crt' ],
    }

This will generate a cert `/etc/stunnel/certs/imaps.pem` that is the
concatenation of the $components array provided, with a single line in between
each certificate to make stunnel happiest.

Since by default, the `cert` parameter looks for certs that match the service
name in the `/etc/stunnel/certs/` directory, we can omit the `cert` parameter
if we use the `stunnel::cert` class.  Here's a full example:

    include stunnel
    stunnel::tun { 'imaps':
      accept   => '993',
      connect  => '143',
      options  => 'NO_SSLv2',
    }

    stunnel::cert { 'imaps':
      components => [ '/etc/pki/tls/certs/public-cert.crt',
                      '/etc/pki/tls/private/private.key' ],
    }

License
-------

See LICENSE file

Copyright
---------

Copyright &copy; 2013 The Regents of the University of California


Contributors:
-------------

**Yann Vigara**

 * Debian/Ubuntu support

Contact
-------

Aaron Russo <arusso@berkeley.edu>

Support
-------

Please log tickets and issues at the
[Projects site](https://github.com/arusso/puppet-stunnel/issues/)
