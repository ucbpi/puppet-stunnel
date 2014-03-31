# stunnel Module #

[![Build Status](https://travis-ci.org/arusso/puppet-stunnel.png?branch=master)](https://travis-ci.org/arusso/puppet-stunnel)

This is an stunnel module that provides support for multiple tunnels, each with
its own initscript.

## What Is stunnel? ##

stunnel is software that enables you to add an SSL (Secure Sockets Layer) to an existing TCP
service, re-presenting the service on a different TCP port, but wrapped in SSL. stunnel
also allows you to create a secure tunnel between two different computers so that a TCP service
that is present on one computer appears on the other computer. This allows you to securely
split onto two computers, a TCP client and server that are currently working on a single
computer, without having to reconfigure either the client or the server.

stunnel is a system service that is automatically re-established if the tunnel software
crashes. This makes it more robust than a manually-created SSH tunnel.


## How To Generate A Certificate ##

In order to create a tunnel using stunnel, you must first create a digital
certificate. This can be done using the shell `openssl` command
(See `http://www.openssl.org/`). Here is an example:

    openssl genrsa -out key.pem 2048
    openssl req -new -x509 -key key.pem -out cert.pem -days 1095
        Country: AU
        State: South Australia
        Locality: Adelaide
        Organisation: Megacorp Pty Ltd
        Common Name: db.megacorp.com
        Email Address: blackhole@megacorp.com
    cat key.pem cert.pem >> stunnel.pem

For more information, see
https://www.digitalocean.com/community/articles/how-to-set-up-an-ssl-tunnel-using-stunnel-on-ubuntu 
or go crazy Googling.

## How To Use Puppet To Install A Certificate File ##

Install the `.pem` file in the Files directory of your Puppet module. You can then
instruct Puppet to install it anywhere you like. Here is an example of how to use
Puppet to install it in the `/etc/ssl/certs` directory:

    file { '/etc/ssl/certs/mysql_stunnel.pem':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
        mode   => 700,
        source  => 'puppet:///modules/mymodule/mysql_stunnel.pem',
        before  => Stunnel::Tun['mysql_stunnel'],
    }

The `before` attribute ensures that the `.pem' file is present before
Puppet attempts to create a tunnel.

## Examples ##

### Example: Adding an SSL Front End Within A Single Computer ###

This example shows how to use stunnel to take an unencrypted imap email
service on TCP port 143, and present it as an encrypted imap email service
on TCP port 993. The encrypted connection employs the digital certificate
at `/etc/certs/stunnel-imaps.pem`. Here is the Puppet configuration to do this:

    include stunnel
    stunnel::tun { 'imaps':
      accept  => '993',
      connect => 'localhost:143',
      options => 'NO_SSLv2',
      cert    => '/etc/certs/stunnel-imaps.pem',
      client  => false,
    }

### Example: Tunnelling A TCP Port Between Computers ###

This example shows how to create an stunnel tunnel between two different computers.
In particular, this example shows the common case of creating a secure connection
between a MySQL client on one computer (the "client computer") and a MySQL server on a
second computer (the "server computer"). However, you should be able to adapt the
example to work for any non-MySQL TCP connection.

In this example, an stunnel service is installed on the client computer and also
separately on the server computer. The same `.pem` certificate file is provided
to each of them. The two services communicate with each other to establish the
connection from a port on the client computer to a port on the server computer.

In this example, a MySQL client connects to the MySQL server by connecting to TCP port
3306 on the client computer, just as if the MySQL server were running on the client
computer. The stunnel client service on the client computer then accepts the connection
and connects to TCP port 3307 on the server computer using an encrypted protocol that
employs the certificate in the `.pem` file at each end. On the server computer, an stunnel
server service accepts the connection to TCP port 3307 and connects to TCP port 3306 on the
server computer where the MySQL database server is waiting to accept the connection.
The result is that the client thinks that the server is on its computer, and the server
thinks that the client is on its computer.

For the purposes of this example, we assume that the same `.pem` certificate file
has been installed at

    /etc/ssl/certs/mysql_stunnel.pem

on both the client and the server computers. See an earlier section for how to generate
a certificate file.

To create the tunnel, we install an stunnel client service on the client computer
and an stunnel server service on the server computer. Here is the Puppet configuration
to establish the stunnel service on the client computer. This configuration should
only be applied to the client computer. Substitute the name, or IP address, of your
server computer for `db.domain.com`.

    include stunnel
    stunnel::tun { 'mysql_stunnel':
      accept  => '3306',               # The stunnel client will listen to this port.
      connect => "db.domain.com:3307", # The stunnel client will connect to this port.
      options => 'NO_SSLv2',
      cert    => '/etc/ssl/certs/mysql_stunnel.pem',
      client  => true,
    }

Here is the Puppet configuration to establish the stunnel service on the server computer.
This configuration should only be applied to the server computer.

    include stunnel
    stunnel::tun { 'mysql_stunnel':
      accept  => '3307', # The stunnel server will listen to this port.
      connect => '3306', # The stunnel server will connect to this port.
                         # Note: I tried 'localhost:3306', but the 'localhost' stopped it from working.
      options => 'NO_SSLv2',
      cert    => '/etc/ssl/certs/mysql_stunnel.pem',
      client  => false,
    }

In this two-computer example, the client attribute distinguishes an
stunnel client installation from an stunnel server installation. This is critical
because stunnel clients and servers do asymmetric things.
The stunnel client on the client computer accepts
MySQL connections on TCP port 3306 and creates an encrypted connection to TCP port 3307 on
the server computer. The stunnel server on the server computer accepts the encrypted
TCP connection on TCP port 3307 and has an encrypted conversation. It connects to
local TCP port 3306 and transmits the decrypted data.

A significant advantage of using stunnel in this way is that neither the
MySQL client on the client computer, nor the MySQL server on the server
computer need to be configured any differently to make it work. This means
that if you have a MySQL client process and a MySQL server process working
on a single computer, you can use stunnel to split them over two computers
without compromising security.

### Multiple Clients ###

In the two-computer example above, the solution is presented as an stunnel
client/server pair as if they are bound together. In fact, stunnel clients
and servers operate independently as clients and servers. This means that
you can have several different client computers, each configured with an stunnel
client as shown above, and each connecting to the same server computer running
an stunnel server.

### Multiple Tunnels ###

So long as you provide a distinct resource name (`mysql_stunnel` in the above
examples) and use distinct TCP ports for each tunnel, you can use this Puppet
package to create as many tunnels as you like, with a single computer
implementing clients and servers for several different tunnels. Just
declare a different `stunnel::tun` resource for each stunnel client or server.

## Service Notification ##

This stunnel Puppet package restarts the stunnel service if a configuration
change has been made.

## stunnel Generated Configuration Files ##

The package installs a configuration file at:

    /etc/stunnel/conf.d/mysql_stunnel.conf

where `mysql_stunnel` is the name of your `stunnel::tun` resource as above.

This Puppet package also generates an init service configuration script at:

    /etc/init.d/stunnel-mysql_stunnel

where `stunnel-mysql_stunnel` is the name of your `stunnel::tun` resource
with `stunnel-` prepended to it.

## stunnel Status ##

Once you've established your stunnel, you can inspect its state using the
following shell commands:

    /etc/init.d/stunnel-mysql_stunnel status
    /etc/init.d/stunnel-mysql_stunnel start
    /etc/init.d/stunnel-mysql_stunnel restart
    /etc/init.d/stunnel-mysql_stunnel stop

where `stunnel-mysql_stunnel` is the name of your `stunnel::tun` resource
with `stunnel-` prepended to it.

## Installation Errors ##

If you get the error:

    Error: Could not install module 'arusso-stunnel' (latest: v1.0.0)
        Installation would overwrite /etc/puppet/modules/stunnel
        Currently, 'puppetlabs-stunnel' (v0.0.1) is installed to that directory
        Use `puppet module install --target-dir <DIR>` to install modules elsewhere
        Use `puppet module install --force` to install this module anyway

then uninstall the Puppet stunnel model and install the arusso one as follows:

    puppet module uninstall stunnel
    puppet module install arusso-stunnel

## Certificates ##

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

References
----------

    https://www.stunnel.org/

    http://en.wikipedia.org/wiki/Stunnel

    http://en.wikipedia.org/wiki/Secure_Sockets_Layer

    https://www.digitalocean.com/community/articles/how-to-set-up-an-ssl-tunnel-using-stunnel-on-ubuntu 

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

**Ross Williams**

 * Documentation.

Contact
-------

Aaron Russo <arusso@berkeley.edu>

Support
-------

Please log tickets and issues at the
[Projects site](https://github.com/arusso/puppet-stunnel/issues/)
