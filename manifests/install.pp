class stunnel::install {
  include stunnel::data

  package { 'stunnel':
    ensure => installed,
    name   => $stunnel::data::package
  }
}
