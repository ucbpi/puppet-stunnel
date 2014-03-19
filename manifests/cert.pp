# == Define: stunnel::cert
#
# concatenantes multiple certificates into a single cert, and places it in the
# stunnel certificates directory.
#
define stunnel::cert (
  $components,
) {
  include stunnel::data

  $comps = join( $components, ' -c ' )
  $out = "${stunnel::data::cert_dir}/${name}.pem"
  $bin = '/usr/local/bin/stunnel-combine-certs'

  if ! defined ( File[$stunnel::data::cert_dir] ) {
    file { $stunnel::data::cert_dir:
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0555',
    }
  }

  if ! defined ( File['/usr/local/bin/stunnel-combine-certs'] ) {
    file { '/usr/local/bin/stunnel-combine-certs':
      ensure => 'present',
      owner  => 'root',
      group  => 'root',
      mode   => '0555',
      source => 'puppet:///modules/stunnel/stunnel-combine-certs.rb',
    }
  }

  exec { "stunnel-generate-cert-${name}":
    path    => [ '/usr/bin', '/bin' ],
    command => "${bin} -c ${comps} -o ${out} -f",
    onlyif  => "${bin} -c ${comps} -o ${out} -t; test $? -eq 1",
    require => [
      File['/usr/local/bin/stunnel-combine-certs'],
      File[$stunnel::data::cert_dir]
    ]
  }
}
