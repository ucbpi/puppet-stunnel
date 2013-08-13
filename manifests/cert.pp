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
  $out = "${stunnel::data::cert_dir}/${title}.pem"
  $bin = '/usr/local/bin/stunnel-combine-certs'

  exec { "stunnel-generate-cert-${title}":
    path    => [ '/usr/bin', '/bin' ],
    command => "${bin} -c ${comps} -o ${out} -f",
    onlyif  => "${bin} -c ${comps} -o ${out} -t; test $? -eq 1",
  }
}
