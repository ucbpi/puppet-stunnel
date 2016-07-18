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
      options => ['NO_SSLv2', 'NO_SSLv3'],
      cert    => '/etc/certs/stunnel-imaps.pem',
      client  => false,
    }

### Example: Tunnelling A TCP Port Between Computers ###

This example shows how to create an stunnel tunnel between two different computers.
In particular, this example shows the common case of creating a secure connection
between a MySQL client on one computer (the "client computer") and a MySQL server on a
second computer (the "server computer"). However, you should be able to adapt the
example to work for any non-MySQL TCP connection.

In this example, an stunnel service is installed on the client computer and
also separately on the server computer.  The two services communicate with each
other to establish the connection from a port on the client computer to a port
on the server computer.

In this example, a MySQL client connects to the MySQL server by connecting to
TCP port 3306 on the client computer, just as if the MySQL server were running
on the client computer. The stunnel client service on the client computer then
accepts the connection and connects to TCP port 3307 on the server computer
using an encrypted protocol that employs the certificate in the `.pem` file on
the server computer. On the server computer, an stunnel server service accepts
the connection to TCP port 3307 and connects to TCP port 3306 on the server
computer where the MySQL database server is waiting to accept the connection.
The result is that the client thinks that the server is on its computer, and
the server thinks that the client is on its computer.

For the purposes of this example, we assume that the `.pem` certificate file
has been installed at

    /etc/ssl/certs/mysql_stunnel.pem

on the server computer. See an earlier section for how to generate a
certificate file.

To create the tunnel, we install an stunnel client service on the client computer
and an stunnel server service on the server computer. Here is the Puppet configuration
to establish the stunnel service on the client computer. This configuration should
only be applied to the client computer. Substitute the name, or IP address, of your
server computer for `db.domain.com`.

    include stunnel
    stunnel::tun { 'mysql_stunnel':
      accept  => '3306',               # The stunnel client will listen to this port.
      connect => "db.domain.com:3307", # The stunnel client will connect to this port.
      options => ['NO_SSLv2, 'NO_SSLv3'],
      client  => true,
    }

Here is the Puppet configuration to establish the stunnel service on the server computer.
This configuration should only be applied to the server computer.

    include stunnel
    stunnel::tun { 'mysql_stunnel':
      accept  => '3307', # The stunnel server will listen to this port.
      connect => '3306', # The stunnel server will connect to this port.
                         # Note: I tried 'localhost:3306', but the 'localhost' stopped it from working.
      options => ['NO_SSLv2', 'NO_SSLv3'],
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

So long as you provide a distinct resource name (`mysql\_stunnel` in the above
examples) and use distinct TCP ports for each tunnel, you can use this Puppet
package to create as many tunnels as you like, with a single computer
implementing clients and servers for several different tunnels. Just
declare a different `stunnel::tun` resource for each stunnel client or server.

## stunnel::tun Attributes ##

### accept ###

Specify the port (and optionally IP address) on which stunnel should listen
for connections.

For an stunnel client, this will typically be the standard port for a service
(e.g. 3306 for MySQL), as the tunnel is presenting the port to its user software.

For an stunnel server, this will typically be a non-standard port that is being
used to construct the tunnel (3307 is often used for MySQL as it is next to 3306).

    accept  => '993',                # Listen on all IPv4 addresses on port 993.
    accept  => '3307',               # Listen on all IPv4 addresses on port 3307.
    accept  => '192.168.0.2:3306'    # Listen only on IPv4 address 192.168.0.2 on port 3306.
    accept  => ':::993',             # Listen on all IPv6 addresses on port 993.

This attribute must be specified.

This attribute controls the `accept` service-level option in the stunnel configuration file.

For more information on this attribute, see [the stunnel documentation](https://www.stunnel.org/static/stunnel.html)

### cafile ###

Specify the location of the cafile.

    cafile => '/etc/pki/tls/certs/cafile.crt'

### cert ###

Specify the location of the certificate file. See an earlier section
for how to create and install a certificate file.

    cert => '/etc/ssl/certs/mysql_stunnel.pem',

This attribute controls the `cert` service-level option in the stunnel configuration file.

The behaviour when this parameter is not specified depends on the value of the
`client` parameter. If `client` is `false`, the cert option will be set to look
for certs that match the service name in the `/etc/stunnel/certs` directory. If
`client` is `true`, the cert option will be omitted in the stunnel
configuration file.

### client ###

Specify whether the installation of stunnel that you are configuring is an
stunnel client (true) or an stunnel server (false).

    client => false,
    client => true,

This attribute must be specified.

This attribute controls the `client` service-level option in the stunnel configuration file.

### debug ###

Specify the level of detail that you want in the log file. Specify 0 for the least
logging, and 7 for the most logging.

    debug => '0',   # emerg
    debug => '1',   # alert
    debug => '2',   # crit
    debug => '3',   # err
    debug => '4',   # warning
    debug => '5',   # notice
    debug => '6',   # info
    debug => '7',   # debug

This attribute is optional and defaults to '5'.

See also the `output` attribute which specifies where the logfile is.

This attribute controls the `debug` service-level option in the stunnel configuration file.

### failover ###

Specify the failover strategy when using multiple back-end servers.

This attribute does not have any effect if you are not specifying multiple backend servers (as an array) as `connect` value.

Valid options are `rr` (round-robin) or `prio` (priority/failover, where stunnel will try to connect
to the first backend, then second, etc.).

This attribute defaults to `rr`.

### global_opts ###

Specify any global options that you wish to appear in the stunnel
configuration file, but which this Puppet module does not support. By
"global" is meant options that are specific to the stunnel installation
as a whole, rather than to a specific tunnel.

    global_opts => { 'setuid' => '32', 'setgid' => '104' },

This attribute is optional and defaults to the empty hash {}.

This attribute can be used to control arbitrary global
options in the stunnel configuration file.

Support for assigning multiple global opts as an array is also available.

    global_opts => { 'socket' => ['l:TCP_NODELAY=1', 'r:TCP_NODELAY=1'] }

For information on stunnel global options, see [the stunnel documentation](https://www.stunnel.org/static/stunnel.html)

### install\_service ###

Specify whether you want this stunnel Puppet module to install stunnel as a
system service. Installing as a service currently places a sysvinit style
initscript for each tunnel inside of /etc/init.d/stunnel-\<name\>.

    install_service => false,
    install_service => true,

This attribute is optional and defaults to `true`.

This attribute controls the installation of the init-script for this tunnel. If
set to true, the init script will be installed. If set to false, the init-script
will be removed.

### service\_init\_system ###

Specify which init system will be managing the service. If set to 'sysv' then
a sysvinit style initscript for each tunnel will be placed inside of
/etc/init.d/stunnel-\<name\>. If set to 'systemd' then a systemd service unit
config will be placed in /etc/systemd/system/stunnel-\<name\>.service.

    service_init_system => 'sysv',
    service_init_system => 'systemd',

This attribute is optional and defaults to `sysv`.

### options ###

Specify any options that you want to pass to OpenSSL.

    options => ['NO_SSLv2', 'NO_SSLv3'],     # SSLv2 is turrible. See: http://osvdb.org/56387
                                             # So is SSLv3. See https://www.openssl.org/~bodo/ssl-poodle.pdf

This attribute is optional and defaults to the empty array []. For backwards
compatability, a single option can be passed as a string.

For more information on this attribute, see [the stunnel documentation](https://www.stunnel.org/static/stunnel.html)

### output ###

Specify the location of the stunnel log file.

    output  => '/var/log/stunnel/mysql_stunnel.log',  # The stunnel log file.

This attribute is optional and defaults to either /var/log/stunnel/$name (EL
based systems) or /var/log/stunnel4/$name (Debian based systems).

See also the `debug` attribute which specifies the level of detail in the stunnel
log file.

This attribute controls the `output` service-level option in the stunnel configuration file.

### service_opts ###

Specify any service-level options that you wish to appear in the stunnel
configuration file, but which this Puppet module does not support. By
"service-level" is meant options that are specific to a particular
tunnel configuration rather than the whole stunnel installation.

    service_opts => { 'protocol' => 'imap', 'TIMEOUTbusy' => '60' },

This attribute is optional and defaults to the empty hash `{}`.

This attribute can be used to control arbitrary service-level
options in the stunnel configuration file.

For information on stunnel service-level options, see [the stunnel documentation](https://www.stunnel.org/static/stunnel.html)

### template ###

Specify a Puppet ERB template for the stunnel configuration file.

    template => template('megacorp_stunnel/stunnel.cfg.erb'),

This attribute is optional and defaults to a template with sensible default values.

This attribute controls the overall form of the stunnel configuration file.

### timeoutidle ###

Specify the number of seconds that stunnel will allow a connection to
be idle before terminating it.

If you set this attribute too low, then you will experience seemingly
spurious disconnections that might cause havoc. If you set this attribute
too high, stunnel will keep open connections to zombie clients. Given
that idle connections do not use up many resources, it's probably best
to err on the high side, which is why the default is 12 hours.

    timeoutidle => '10',       # Ten seconds.
    timeoutidle => '60',       # One minute.
    timeoutidle => '3600',     # One hour.
    timeoutidle => '43200',    # 12 hours.
    timeoutidle => '86400',    # One day.
    timeoutidle => '604800',   # One week.

This attribute is optional and defaults to 43200 (12 hours).

This attribute controls the `TIMEOUTidle` service-level option of
the stunnel configuration file.

## Service Notification ##

This stunnel Puppet package restarts the stunnel service if a configuration
change has been made.

## stunnel Generated Configuration Files ##

The package installs a configuration file at:

    /etc/stunnel/conf.d/mysql_stunnel.conf

where `mysql\_stunnel` is the name of your `stunnel::tun` resource as above.

This Puppet package also generates an init service configuration script at:

    /etc/init.d/stunnel-mysql_stunnel

where `stunnel-mysql\_stunnel` is the name of your `stunnel::tun` resource
with `stunnel-` prepended to it.

## stunnel Status ##

Once you've established your stunnel, you can inspect its state using the
following shell commands:

    /etc/init.d/stunnel-mysql_stunnel status
    /etc/init.d/stunnel-mysql_stunnel start
    /etc/init.d/stunnel-mysql_stunnel restart
    /etc/init.d/stunnel-mysql_stunnel stop

where `stunnel-mysql\_stunnel` is the name of your `stunnel::tun` resource
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

## Operational Errors ##

If you find that the tunnel isn't working, look in the log file.
If you see:

    connect_blocking: s_poll_wait

then one reason why this might be happening is if your firewall
is blocking the tunnel.

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
      options  => ['NO_SSLv2', 'NO_SSLv3'],
    }

    stunnel::cert { 'imaps':
      components => [ '/etc/pki/tls/certs/public-cert.crt',
                      '/etc/pki/tls/private/private.key' ],
    }

References
----------

* https://www.stunnel.org/
* http://en.wikipedia.org/wiki/Stunnel
* http://en.wikipedia.org/wiki/Secure_Sockets_Layer
* https://www.digitalocean.com/community/articles/how-to-set-up-an-ssl-tunnel-using-stunnel-on-ubuntu

License
-------

See LICENSE file

Copyright
---------

Copyright &copy; 2016 The Regents of the University of California


Contributors:
-------------

* **Yann Vigara**
* **Ross Williams**
* **John Cooper**
* **Francois Gouteroux**
* **Stephen Hoekstra**
* **mjs510**
* **Olivier Fontannaud**

Contact
-------

Aaron Russo <arusso@berkeley.edu>

Support
-------

Please log tickets and issues at the
[Projects site](https://github.com/arusso/puppet-stunnel/issues/)
